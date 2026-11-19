
from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware

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
        "buah mangga menggunakan metode SVM dan Naive Bayes"
    ),
    version="1.0"
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

NB_PATH = os.path.join(MODEL_DIR, "naive_bayes.pkl")
SVM_PATH = os.path.join(MODEL_DIR, "svm.pkl")


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


def muat_model():

    global naive_bayes, svm

    try:

        if os.path.exists(NB_PATH):
            naive_bayes = joblib.load(NB_PATH)
            print("\nModel Naive Bayes berhasil dimuat.")
        else:
            print("\nFile naive_bayes.pkl tidak ditemukan.")

        if os.path.exists(SVM_PATH):
            svm = joblib.load(SVM_PATH)
            print("Model SVM berhasil dimuat.")
        else:
            print("File svm.pkl tidak ditemukan.")

    except Exception as e:
        raise RuntimeError(
            f"Gagal memuat model: {e}"
        )


muat_model()


if naive_bayes is None and svm is None:
    raise RuntimeError(
        "Tidak ada model yang berhasil dimuat. "
        "Periksa file model di folder backend/model."
    )


# Informasi model

print("\n========================================")
print("             INFORMASI MODEL")
print("========================================")


if naive_bayes is not None:

    print("Naive Bayes :", type(naive_bayes).__name__)

    print(
        "Jumlah fitur NB:",
        getattr(
            naive_bayes,
            "n_features_in_",
            "Tidak tersedia"
        )
    )


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

    try:

        # Memastikan gambar valid
        if gambar is None:
            raise ValueError("Gambar tidak valid.")

        # Konversi BGR ke HSV
        hsv = cv2.cvtColor(
            gambar,
            cv2.COLOR_BGR2HSV
        )

        fitur = []

        # Ekstraksi histogram 3 channel HSV
        for channel in range(3):

            data = hsv[:, :, channel]

            hist = cv2.calcHist(
                [data],
                [0],
                None,
                [18],
                [0, 256]
            )

            hist = cv2.normalize(
                hist,
                hist
            ).flatten()

            fitur.extend(hist)

        # Total fitur = 18 x 3 = 54
        fitur = np.array(
            fitur,
            dtype=np.float32
        ).reshape(1, -1)

        return fitur

    except Exception as e:

        raise ValueError(
            f"Gagal melakukan ekstraksi fitur: {e}"
        )


# ==========================================
# 6. HALAMAN UTAMA API
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
# 7. ENDPOINT PREDIKSI MANGGA
# ==========================================

@app.post("/predict")
async def predict(
    file: UploadFile = File(...),
    metode: str = "svm"
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

        print("\n================================")
        print("       PROSES PREDIKSI")
        print("================================")

        print("Nama file :", file.filename)
        print("Ukuran gambar :", gambar.shape)
        print("Jumlah fitur :", fitur.shape[1])
        print("Metode :", metode)

        # ----------------------------------
        # D. MEMILIH MODEL
        # ----------------------------------

        metode = metode.lower().strip()

        if metode == "svm":

            if svm is None:

                raise HTTPException(
                    status_code=500,
                    detail="Model SVM belum tersedia."
                )

            model = svm

        elif metode in ["naive_bayes", "nb"]:

            if naive_bayes is None:

                raise HTTPException(
                    status_code=500,
                    detail="Model Naive Bayes belum tersedia."
                )

            model = naive_bayes

        else:

            raise HTTPException(
                status_code=400,
                detail="Metode harus svm atau naive_bayes."
            )

        # ----------------------------------
        # E. MEMERIKSA JUMLAH FITUR
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
        # F. MELAKUKAN PREDIKSI
        # ----------------------------------

        hasil = model.predict(fitur)[0]

        print("Hasil prediksi :", hasil)

        # ----------------------------------
        # G. MENGAMBIL PROBABILITAS
        # ----------------------------------

        probabilitas = None

        if hasattr(model, "predict_proba"):

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

        # ----------------------------------
        # H. MENGEMBALIKAN HASIL
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
# 8. CEK STATUS MODEL
# ==========================================

@app.get("/model-status")
def model_status():

    return {
        "naive_bayes": naive_bayes is not None,
        "svm": svm is not None,
        "status": "aktif"
    }


# ==========================================
# 9. CEK FITUR EKSTRAKSI
# ==========================================

@app.get("/feature-status")
def feature_status():

    return {
        "metode_ekstraksi": "HSV Histogram",
        "channel": ["H", "S", "V"],
        "jumlah_bin_per_channel": 18,
        "total_fitur": 54,
        "status": "aktif"
    }
