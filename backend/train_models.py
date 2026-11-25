import argparse
import collections
import hashlib
import os
import tempfile
import zipfile

import cv2
import joblib
import numpy as np
from imblearn.over_sampling import RandomOverSampler
from imblearn.pipeline import Pipeline
from sklearn.metrics import accuracy_score, classification_report
from sklearn.model_selection import StratifiedKFold, cross_val_score
from sklearn.naive_bayes import GaussianNB
from sklearn.preprocessing import StandardScaler
from sklearn.svm import SVC

from main import ekstraksi_fitur


BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_DIR = os.path.join(BASE_DIR, "model")
KELAS = ("OverRipe", "Ripe", "UnRipe")
LABEL_FOLDER = {
    "overipe": "OverRipe",
    "overripe": "OverRipe",
    "ripe": "Ripe",
    "unripe": "UnRipe",
}


def _info_gambar_mangga(nama):
    bagian = [part for part in nama.replace("\\", "/").split("/") if part]
    indeks_split = next(
        (index for index, part in enumerate(bagian) if part.lower() in ("train", "test")),
        None,
    )

    if indeks_split is None or indeks_split + 2 >= len(bagian):
        return None

    nama_file = bagian[-1].lower()
    if not nama_file.startswith("mango_"):
        return None

    split = bagian[indeks_split].lower()
    kelas_folder = bagian[indeks_split + 1].lower()
    label = LABEL_FOLDER.get(kelas_folder)

    if label is None:
        raise ValueError(f"Folder kelas mangga tidak dikenali: {nama}")

    return split, label


def _muat_dataset(zip_path):
    data_train = {}
    data_test = {}

    with zipfile.ZipFile(zip_path) as arsip:
        for nama in arsip.namelist():
            info = _info_gambar_mangga(nama)
            if info is None:
                continue

            split, label = info
            konten = arsip.read(nama)
            digest = hashlib.sha256(konten).digest()
            tujuan = data_train if split == "train" else data_test

            if digest in tujuan:
                if tujuan[digest][1] != label:
                    raise ValueError(f"Gambar duplikat memiliki label berbeda: {nama}")
                continue

            gambar = cv2.imdecode(
                np.frombuffer(konten, dtype=np.uint8),
                cv2.IMREAD_COLOR,
            )
            if gambar is None:
                raise ValueError(f"Gambar tidak dapat dibaca: {nama}")

            tujuan[digest] = (ekstraksi_fitur(gambar)[0], label)

    hash_train = set(data_train)
    data_test_bersih = {}
    for digest, sample in data_test.items():
        if digest in hash_train:
            if data_train[digest][1] != sample[1]:
                raise ValueError(
                    "Gambar yang sama memiliki label berbeda antara Train dan Test."
                )
            continue
        data_test_bersih[digest] = sample
    data_test = data_test_bersih

    if not data_train or not data_test:
        raise ValueError("Dataset harus memiliki gambar mango di folder Train dan Test.")

    for split, data in (("Train", data_train), ("Test", data_test)):
        kelas_tersedia = {label for _, label in data.values()}
        if kelas_tersedia != set(KELAS):
            raise ValueError(
                f"Folder {split} harus memiliki semua kelas {list(KELAS)}; "
                f"ditemukan {sorted(kelas_tersedia)}."
            )

    return data_train, data_test


def _pipeline_model():
    return {
        "svm": Pipeline(
            [
                ("scaler", StandardScaler()),
                ("oversampling", RandomOverSampler(random_state=42)),
                ("classifier", SVC(probability=True, random_state=42)),
            ]
        ),
        "naive_bayes": Pipeline(
            [
                ("oversampling", RandomOverSampler(random_state=42)),
                ("classifier", GaussianNB()),
            ]
        ),
    }


def latih_model(zip_path, output_dir=MODEL_DIR):
    data_train, data_test = _muat_dataset(zip_path)
    X_train = np.asarray([fitur for fitur, _ in data_train.values()])
    y_train = np.asarray([label for _, label in data_train.values()])
    X_test = np.asarray([fitur for fitur, _ in data_test.values()])
    y_test = np.asarray([label for _, label in data_test.values()])

    print("Jumlah foto train:", len(y_train), dict(collections.Counter(y_train)))
    print("Jumlah foto test :", len(y_test), dict(collections.Counter(y_test)))

    cv = StratifiedKFold(n_splits=5, shuffle=True, random_state=42)
    model_scores = {}
    trained_models = _pipeline_model()

    for nama, model in trained_models.items():
        scores = cross_val_score(model, X_train, y_train, cv=cv, scoring="accuracy")
        model.fit(X_train, y_train)
        prediksi = model.predict(X_test)
        model_scores[nama] = float(scores.mean())

        print(f"\n{nama}: rata-rata akurasi CV 5-fold = {scores.mean():.3f}")
        print(f"Akurasi test terpisah = {accuracy_score(y_test, prediksi):.3f}")
        print(
            classification_report(
                y_test,
                prediksi,
                labels=KELAS,
                zero_division=0,
            )
        )

    model_terbaik = max(model_scores, key=model_scores.get)
    print(f"Model terbaik berdasarkan cross-validation: {model_terbaik}")

    os.makedirs(output_dir, exist_ok=True)
    with tempfile.TemporaryDirectory(dir=output_dir) as staging_dir:
        output = {
            "svm.pkl": trained_models["svm"],
            "naive_bayes.pkl": trained_models["naive_bayes"],
            "best_model.pkl": trained_models[model_terbaik],
        }

        for nama_file, model in output.items():
            joblib.dump(model, os.path.join(staging_dir, nama_file))

        for nama_file in output:
            os.replace(
                os.path.join(staging_dir, nama_file),
                os.path.join(output_dir, nama_file),
            )


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Latih model kematangan mangga dari ZIP dataset berlabel."
    )
    parser.add_argument(
        "dataset_zip",
        help="Path ZIP dataset dengan folder Train/Test dan kelas kematangan.",
    )
    parser.add_argument(
        "--output-dir",
        default=MODEL_DIR,
        help="Folder keluaran model (default: backend/model).",
    )
    arguments = parser.parse_args()
    latih_model(arguments.dataset_zip, arguments.output_dir)
