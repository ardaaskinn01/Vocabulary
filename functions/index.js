const functions = require("firebase-functions");
const admin = require("firebase-admin");
const axios = require("axios");
const express = require("express");
require("dotenv").config();


admin.initializeApp();

const googleApiKey = process.env.GOOGLE_API_KEY;
const appleSharedSecret = process.env.APPLE_SHARED_SECRET;

const app = express();
app.use(express.json());

async function verifyAppleReceipt(receiptData) {
  const productionUrl = "https://buy.itunes.apple.com/verifyReceipt";
  const sandboxUrl = "https://sandbox.itunes.apple.com/verifyReceipt";

  // Önce production ortamına isteği gönder
  let response = await axios.post(productionUrl, {
    "receipt-data": receiptData,
    "password": appleSharedSecret,
  });

  // Eğer 21007 hatası dönerse sandbox ortamına yönlendir
  if (response.data.status === 21007) {
    response = await axios.post(sandboxUrl, {
      "receipt-data": receiptData,
      "password": appleSharedSecret,
    });
  }

  return response.data.status === 0;
}

app.post("/verifyPurchase", async (req, res) => {
  const {userId, purchaseToken, platform} = req.body;

  if (!userId || !purchaseToken || !platform) {
    return res.status(400).json({success: false, message: "Eksik parametreler."});
  }

  try {
    let isValidPurchase = false;

    if (platform === "android") {
      const googleApiUrl = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/com.aasoft.ingilizce/purchases/subscriptions/premiumaccess1/tokens/${purchaseToken}`;

      const googleResponse = await axios.get(`${googleApiUrl}?key=${googleApiKey}`);
      isValidPurchase = googleResponse.data.purchaseState === 0;
    } else if (platform === "ios") {
      isValidPurchase = await verifyAppleReceipt(purchaseToken);
    }

    if (isValidPurchase) {
      await admin.firestore().collection("users").doc(userId).update({isPremium: true});
      return res.json({success: true, message: "Premium doğrulandı!"});
    } else {
      return res.status(403).json({success: false, message: "Satın alma geçersiz."});
    }
  } catch (error) {
    return res.status(500).json({success: false, message: "Satın alma doğrulanamadı."});
  }
});

exports.verifyPurchase = functions.https.onRequest(app);
