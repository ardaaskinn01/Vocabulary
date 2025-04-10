const functions = require("firebase-functions");
const admin = require("firebase-admin");
const axios = require("axios");
const express = require("express");
require("dotenv").config();

admin.initializeApp();

const googleApiKey = "AIzaSyCQzb7Jo_QpAxLl6fe2lf3z1YSOIUTaVAk"
const appleSharedSecret = "6f89c9b9893b4689a79e4d35b4169ad6"

const app = express();
app.use(express.json());

async function verifyAppleReceipt(receiptData) {
  const productionUrl = "https://buy.itunes.apple.com/verifyReceipt";
  const sandboxUrl = "https://sandbox.itunes.apple.com/verifyReceipt";

  try {
    let response = await axios.post(productionUrl, {
      "receipt-data": receiptData,
      "password": appleSharedSecret,
      "exclude-old-transactions": true,
    });

    // Apple receipt status logu eklendi
    console.log("Apple receipt status (prod):", response.data.status);

    if (response.data.status === 21007) {
      response = await axios.post(sandboxUrl, {
        "receipt-data": receiptData,
        "password": appleSharedSecret,
        "exclude-old-transactions": true,
      });

      // Sandbox durumu loglandı
      console.log("Apple receipt status (sandbox):", response.data.status);
    }

    if (response.data.status === 0) {
      const latestReceipt =
        response.data.latest_receipt_info?.length > 0
          ? response.data.latest_receipt_info[response.data.latest_receipt_info.length - 1]
          : response.data.receipt;

      const expiresDateMs = parseInt(latestReceipt.expires_date_ms);
      return { valid: true, expiresDate: expiresDateMs };
    }

    return { valid: false };
  } catch (error) {
    console.error("Apple receipt verification error:", error);
    return { valid: false };
  }
}

app.post("/verifyPurchase", async (req, res) => {
  const { userId, purchaseToken, platform } = req.body;

  if (!userId || !purchaseToken || !platform) {
    return res.status(400).json({ success: false, message: "Eksik parametreler." });
  }

  try {
    let isValidPurchase = false;
    let expiresDate = null;

    if (platform === "android") {
      const googleApiUrl = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/com.aasoft.ingilizce/purchases/subscriptions/premiumaccess1/tokens/${purchaseToken}`;

      const googleResponse = await axios.get(`${googleApiUrl}?key=${googleApiKey}`);
      const data = googleResponse.data;

      // Yeni kontrol: hem purchaseState hem acknowledgementState kontrolü
      isValidPurchase = data.purchaseState === 0 && data.acknowledgementState === 1;
      expiresDate = data.expiryTimeMillis;

      console.log("Google Play yanıtı:", data);
    } else if (platform === "ios") {
      const result = await verifyAppleReceipt(purchaseToken);
      isValidPurchase = result.valid;
      expiresDate = result.expiresDate;
    }

    if (isValidPurchase) {
      try {
        // Kullanıcı yoksa yeni doküman oluşturulacak şekilde güncellendi
        await admin.firestore().collection("users").doc(userId).set({
          isPremium: true,
          subscriptionEnd: expiresDate,
        }, { merge: true });

        return res.json({
          success: true,
          message: "Premium doğrulandı!",
          expiresDate,
        });
      } catch (error) {
        console.error("Firestore güncelleme hatası:", error);
        return res.status(500).json({
          success: false,
          message: "Veritabanı güncellenemedi.",
          error: error.message,
        });
      }
    } else {
      return res.status(403).json({
        success: false,
        message: "Satın alma geçersiz.",
      });
    }
  } catch (error) {
    console.error("Purchase verification error:", error);
    return res.status(500).json({
      success: false,
      message: "Satın alma doğrulanamadı.",
      error: error.message,
    });
  }
});

exports.verifyPurchase = functions.https.onRequest(app);