import unittest
from types import SimpleNamespace

from fastapi import HTTPException

import main


class ModelClassValidationTests(unittest.TestCase):
    def test_accepts_ripeness_classes(self):
        model = SimpleNamespace(classes_=["OverRipe", "Ripe", "UnRipe"])

        self.assertIsNone(main.validasi_kelas_model(model, "tes"))

    def test_rejects_non_ripeness_classes(self):
        model = SimpleNamespace(classes_=["Defective", "Healthy"])

        with self.assertRaisesRegex(RuntimeError, "tidak sesuai"):
            main.validasi_kelas_model(model, "tes")

    def test_selects_svm_for_supported_predictions(self):
        self.assertIs(main.pilih_model("svm"), main.svm)

    def test_rejects_naive_bayes_to_keep_one_prediction_model(self):
        with self.assertRaises(HTTPException) as error:
            main.pilih_model("naive_bayes")

        self.assertEqual(error.exception.status_code, 400)


if __name__ == "__main__":
    unittest.main()
