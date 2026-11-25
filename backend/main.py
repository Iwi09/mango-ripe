from fastapi import FastAPI, File, UploadFile, HTTPException, Form, Query
from fastapi.middleware.cors import CORSMiddleware
from typing import Optional

import numpy as np
import cv2
import joblib
import os


# ==========================================
# 1. KONFIGURASI FASTAPI
# ==========================================

app = FastAPI(
    title="API Deteksi Kematangan Mangga",
    description=(
        "API untuk mendeteksi tingkat kematangan "
        "buah mangga menggunakan model SVM"
    ),
    version="1.2"
)


# ==========================================
# 2. KONFIGURASI CORS
# ==========================================

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ==========================================
# 3. LOKASI FOLDER MODEL
# ==========================================

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_DIR = os.path.join(BASE_DIR, "model")

SVM_PATH = os.path.join(MODEL_DIR, "svm.pkl")
KELAS_KEMATANGAN = {"OverRipe", "Ripe", "UnRipe"}
SUMBER_MODEL = "asadullahprl/fruits-ripeness-classification-dataset@v1"


print("\n========================================")
print("       API DETEKSI KEMATANGAN MANGGA")
print("========================================")

print("Lokasi backend :", BASE_DIR)
print("Lokasi model   :", MODEL_DIR)


if not os.path.exists(MODEL_DIR):
    raise RuntimeError(
        f"Folder model tidak ditemukan: {MODEL_DIR}"
    )


print("\nDaftar file dalam folder model:")

for nama_file in os.listdir(MODEL_DIR):
    print("-", nama_file)


# ==========================================
# 4. MEMUAT MODEL MACHINE LEARNING
# ==========================================

naive_bayes = None
svm = None


def validasi_kelas_model(model, nama_model):
    kelas_model = getattr(model, "classes_", None)

    if kelas_model is None:
        raise RuntimeError(
            f"Model {nama_model} tidak memiliki informasi kelas."
        )

    kelas_model = {str(kelas) for kelas in kelas_model}

    if kelas_model != KELAS_KEMATANGAN:
        raise RuntimeError(
            f"Kelas model {nama_model} tidak sesuai. "
            f"Diharapkan {sorted(KELAS_KEMATANGAN)}, "
            f"ditemukan {sorted(kelas_model)}."
        )


def muat_model():

    global svm

    try:

        if os.path.exists(SVM_PATH):
            svm = joblib.load(SVM_PATH)
            validasi_kelas_model(svm, "SVM")
            print("Model SVM berhasil dimuat.")
        else:
            print("File svm.pkl tidak ditemukan.")

    except Exception as e:
        raise RuntimeError(
            f"Gagal memuat model: {e}"
        )


muat_model()


if svm is None:
    raise RuntimeError(
        "Model SVM tidak berhasil dimuat. "
        "Periksa file backend/model/svm.pkl."
    )


# Informasi model

print("\n========================================")
print("             INFORMASI MODEL")
print("========================================")


if svm is not None:

    print("SVM :", type(svm).__name__)

    print(
        "Jumlah fitur SVM:",
        getattr(
            svm,
            "n_features_in_",
            "Tidak tersedia"
        )
    )


# ==========================================
# 5. EKSTRAKSI FITUR HSV
# ==========================================

def ekstraksi_fitur(gambar):
    """
    HARUS sama persis dengan extract_hsv_features() di notebook training:
    1. resize 224x224
    2. BGR -> HSV
    3. crop bagian tengah (20% - 80%)
    4. per channel: mean, std, histogram 16 bin
       (H: range 0-180, S dan V: range 0-256)
    Total fitur = 3 x (2 + 16) = 54
    """

    try:

        if gambar is None:
            raise ValueError("Gambar tidak valid.")

        # 1. Resize
        gambar = cv2.resize(gambar, (224, 224))

        # 2. Konversi BGR ke HSV
        hsv = cv2.cvtColor(
            gambar,
            cv2.COLOR_BGR2HSV
        )

        # 3. Crop bagian tengah gambar
        tinggi, lebar = hsv.shape[:2]

        hsv = hsv[
            int(tinggi * 0.2):int(tinggi * 0.8),
            int(lebar * 0.2):int(lebar * 0.8)
        ]

        fitur = []

        # 4. Mean, std, dan histogram tiap channel
        for channel in range(3):

            data = hsv[:, :, channel]

            fitur.append(np.mean(data))
            fitur.append(np.std(data))

            hist = cv2.calcHist(
                [hsv],
                [channel],
                None,
                [16],
                [0, 180] if channel == 0 else [0, 256]
            )

            hist = cv2.normalize(
                hist,
                hist
            ).flatten()

            fitur.extend(hist)

        fitur = np.array(
            fitur,
            dtype=np.float64
        ).reshape(1, -1)

        return fitur

    except Exception as e:

        raise ValueError(
            f"Gagal melakukan ekstraksi fitur: {e}"
        )


# ==========================================
# 6. NORMALISASI NAMA METODE
# ==========================================

def normalisasi_metode(nilai):
    """
    Menyamakan berbagai penulisan metode dari Flutter, misalnya:
    'Naive Bayes', 'naive bayes', 'naive-bayes', 'NB'  -> 'naive_bayes'
    'SVM', 'svm'                                       -> 'svm'
    """

    if not nilai:
        return "svm"

    nilai = (
        str(nilai)
        .lower()
        .strip()
        .replace(" ", "_")
        .replace("-", "_")
    )

    if nilai in ["svm"]:
        return "svm"

    if nilai in ["naive_bayes", "naivebayes", "nb"]:
        return "naive_bayes"

    return nilai


def pilih_model(metode):
    if metode != "svm":
        raise HTTPException(
            status_code=400,
            detail="Aplikasi menggunakan SVM saja karena hasil validasinya lebih baik."
        )

    if svm is None:
        raise HTTPException(
            status_code=500,
            detail="Model SVM belum tersedia."
        )

    return svm


# ==========================================
# 7. HALAMAN UTAMA API
# ==========================================

@app.get("/")
def home():

    return {
        "status": "berhasil",
        "pesan": "API Deteksi Kematangan Mangga aktif",

        "model_tersedia": {
            "naive_bayes": naive_bayes is not None,
            "svm": svm is not None
        },

        "endpoint": {
            "prediksi": "/predict",
            "status_model": "/model-status",
            "dokumentasi": "/docs"
        }
    }


# ==========================================
# 8. ENDPOINT PREDIKSI MANGGA
# ==========================================

@app.post("/predict")
async def predict(
    file: UploadFile = File(...),

    # PERBAIKAN: metode bisa dikirim lewat form-data ATAU query string
    metode_form: Optional[str] = Form(None, alias="metode"),
    metode_query: Optional[str] = Query(None, alias="metode"),

    # Flutter mengirim field bernama "model_name", jadi ikut diterima
    model_name_form: Optional[str] = Form(None, alias="model_name"),
    model_name_query: Optional[str] = Query(None, alias="model_name"),
):

    try:

        # ----------------------------------
        # A. MEMBACA FILE GAMBAR
        # ----------------------------------

        contents = await file.read()

        if not contents:

            raise HTTPException(
                status_code=400,
                detail="File gambar kosong."
            )

        # ----------------------------------
        # B. MEMBACA FORMAT GAMBAR
        # ----------------------------------

        image_array = np.frombuffer(
            contents,
            dtype=np.uint8
        )

        gambar = cv2.imdecode(
            image_array,
            cv2.IMREAD_COLOR
        )

        if gambar is None:

            raise HTTPException(
                status_code=400,
                detail="Format gambar tidak valid."
            )

        # ----------------------------------
        # C. EKSTRAKSI FITUR HSV
        # ----------------------------------

        fitur = ekstraksi_fitur(gambar)

        # ----------------------------------
        # D. MENENTUKAN METODE
        # ----------------------------------

        metode_mentah = (
            metode_form
            or metode_query
            or model_name_form
            or model_name_query
        )
        metode = normalisasi_metode(metode_mentah)

        print("\n================================")
        print("       PROSES PREDIKSI")
        print("================================")

        print("Nama file :", file.filename)
        print("Ukuran gambar :", gambar.shape)
        print("Jumlah fitur :", fitur.shape[1])
        print("Metode diterima (form) :", metode_form)
        print("Metode diterima (query):", metode_query)
        print("model_name diterima (form) :", model_name_form)
        print("model_name diterima (query):", model_name_query)
        print("Metode dipakai :", metode)

        # ----------------------------------
        # E. MEMILIH MODEL
        # ----------------------------------

        model = pilih_model(metode)

        # ----------------------------------
        # F. MEMERIKSA JUMLAH FITUR
        # ----------------------------------

        jumlah_fitur = getattr(
            model,
            "n_features_in_",
            None
        )

        if (
            jumlah_fitur is not None
            and jumlah_fitur != fitur.shape[1]
        ):

            raise HTTPException(
                status_code=500,
                detail=(
                    f"Jumlah fitur tidak sesuai. "
                    f"Model membutuhkan {jumlah_fitur}, "
                    f"tetapi backend menghasilkan {fitur.shape[1]}."
                )
            )

        # ----------------------------------
        # G. MELAKUKAN PREDIKSI
        # ----------------------------------

        hasil = model.predict(fitur)[0]

        print("Hasil prediksi :", hasil)

        # ----------------------------------
        # H. MENGAMBIL PROBABILITAS
        # ----------------------------------

        probabilitas = None

        if hasattr(model, "predict_proba"):

            try:

                proba = model.predict_proba(fitur)[0]

                probabilitas = {
                    str(label): round(
                        float(nilai) * 100,
                        2
                    )
                    for label, nilai in zip(
                        model.classes_,
                        proba
                    )
                }

            except Exception as e:

                # SVM tanpa probability=True akan error di sini,
                # prediksi tetap dikembalikan tanpa probabilitas
                print("Probabilitas tidak tersedia:", str(e))

        # ----------------------------------
        # I. MENGEMBALIKAN HASIL
        # ----------------------------------

        return {
            "status": "berhasil",
            "nama_file": file.filename,
            "metode": metode,
            "hasil_prediksi": str(hasil),
            "jumlah_fitur": int(fitur.shape[1]),
            "probabilitas": probabilitas
        }

    except HTTPException:

        raise

    except Exception as e:

        print("ERROR PREDIKSI:", str(e))

        raise HTTPException(
            status_code=500,
            detail=str(e)
        )


# ==========================================
# 9. CEK STATUS MODEL
# ==========================================

@app.get("/model-status")
def model_status():

    return {
        "naive_bayes": False,
        "svm": svm is not None,
        "training_dataset": SUMBER_MODEL,
        "status": "aktif"
    }


# ==========================================
# 10. CEK FITUR EKSTRAKSI
# ==========================================

@app.get("/feature-status")
def feature_status():

    return {
        "metode_ekstraksi": "HSV mean, std, histogram (crop tengah 224x224)",
        "channel": ["H", "S", "V"],
        "jumlah_bin_per_channel": 16,
        "total_fitur": 54,
        "status": "aktif"
    }