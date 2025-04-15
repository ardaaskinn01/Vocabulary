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
    // Başlangıç logu
    console.log("📩 iOS doğrulama başlatıldı...");

    let response = await axios.post(productionUrl, {
      "receipt-data": receiptData,
      "password": appleSharedSecret,
      "exclude-old-transactions": true,
    });

    console.log("📡 Apple (prod) yanıtı:", response.data);

    if (response.data.status === 21007) {
      // Sandbox’a yönlendir
      console.log("🔁 Sandbox’a geçiliyor (21007)...");
      response = await axios.post(sandboxUrl, {
        "receipt-data": receiptData,
        "password": appleSharedSecret,
        "exclude-old-transactions": true,
      });
      console.log("📡 Apple (sandbox) yanıtı:", response.data);
    }

    // Başarılı doğrulama
    if (response.data.status === 0) {
      const latestReceipt =
        response.data.latest_receipt_info?.length > 0
          ? response.data.latest_receipt_info[response.data.latest_receipt_info.length - 1]
          : response.data.receipt;

      const expiresDateMs = parseInt(latestReceipt.expires_date_ms);
      const productId = latestReceipt.product_id;
      const originalTransactionId = latestReceipt.original_transaction_id;

      return {
        valid: true,
        expiresDate: expiresDateMs,
        productId,
        originalTransactionId,
        fullResponse: response.data,
      };
    }

    // Apple doğrulama başarısız
    return {
      valid: false,
      reason: `Apple status: ${response.data.status}`,
      fullResponse: response.data,
    };

  } catch (error) {
    console.error("❌ Apple receipt verification error:", error);
    return {
      valid: false,
      reason: "Apple sunucusuna ulaşılamadı.",
      fullResponse: null,
    };
  }
}

app.post("/verifyPurchase", async (req, res) => {
  const { userId, purchaseToken, platform } = req.body;

  if (!userId || !purchaseToken || !platform) {
    return res.status(400).json({
      success: false,
      message: "Eksik parametreler: userId, purchaseToken ve platform zorunludur.",
    });
  }

  try {
    let isValidPurchase = false;
    let expiresDate = null;
    let responseMeta = {};

    if (platform === "android") {
      const googleApiUrl = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/com.aasoft.ingilizce/purchases/subscriptions/premiumaccess1/tokens/${purchaseToken}`;

      const googleResponse = await axios.get(`${googleApiUrl}?key=${googleApiKey}`);
      const data = googleResponse.data;

      isValidPurchase = data.purchaseState === 0 && data.acknowledgementState === 1;
      expiresDate = data.expiryTimeMillis;

      responseMeta = { provider: "google", raw: data };
      console.log("✅ Google Play yanıtı:", data);

    } else if (platform === "ios") {
      const result = await verifyAppleReceipt(purchaseToken);
      isValidPurchase = result.valid;
      expiresDate = result.expiresDate;
      responseMeta = result;

      if (!isValidPurchase) {
        console.warn("⚠️ iOS satın alma doğrulanamadı:", result.reason);
      } else {
        console.log("✅ Apple satın alma doğrulandı:", result.productId);
      }
    }

    if (isValidPurchase) {
      try {
        await admin.firestore().collection("users").doc(userId).set({
          isPremium: true,
          subscriptionEnd: expiresDate,
          lastValidatedAt: Date.now(),
          source: platform,
        }, { merge: true });

        return res.json({
          success: true,
          message: "Premium doğrulandı!",
          expiresDate,
          debug: responseMeta,
        });
      } catch (error) {
        console.error("🔥 Firestore yazım hatası:", error);
        return res.status(500).json({
          success: false,
          message: "Veritabanı yazımı başarısız.",
          error: error.message,
        });
      }
    } else {
       return res.status(403).json({
          success: false,
          message: "Satın alma geçersiz.",
          reason: responseMeta.reason || "Geçerli cevap alınamadı",
          appleStatus: responseMeta.fullResponse?.status,
          fullResponse: responseMeta.fullResponse,
        });
    }

  } catch (error) {
    console.error("🔥 Genel doğrulama hatası:", error);
    return res.status(500).json({
      success: false,
      message: "Satın alma doğrulama işlemi başarısız.",
      error: error.message,
    });
  }
});

exports.verifyPurchase = functions.https.onRequest(app);