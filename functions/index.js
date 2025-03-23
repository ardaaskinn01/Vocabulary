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

  try {
    // Önce production ortamında dene
    let response = await axios.post(productionUrl, {
      "receipt-data": receiptData,
      "password": appleSharedSecret,
      "exclude-old-transactions": true,
    });

    // Eğer sandbox hatası dönerse sandbox ortamında dene
    if (response.data.status === 21007) {
      response = await axios.post(sandboxUrl, {
        "receipt-data": receiptData,
        "password": appleSharedSecret,
        "exclude-old-transactions": true,
      });
    }

    // Log ekleyelim
    console.log("Apple receipt verification response:", response.data);

    // Sonucu döndür
    if (response.data.status === 0) {
      return {valid: true, data: response.data};
    } else {
      return {valid: false, data: response.data};
    }
  } catch (error) {
    console.error("Apple receipt verification error:", error);
    return {valid: false, error: error.message};
  }
}

app.post("/verifyPurchase", async (req, res) => {
  const {userId, purchaseToken, platform} = req.body;

  if (!userId || !purchaseToken || !platform) {
    return res.status(400).json({success: false, message: "Eksik parametreler."});
  }

  try {
    let isValidPurchase = false;
    let responseData = null;

    if (platform === "android") {
      const googleApiUrl = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/com.aasoft.ingilizce/purchases/subscriptions/premiumaccess1/tokens/${purchaseToken}`;

      const googleResponse = await axios.get(`${googleApiUrl}?key=${googleApiKey}`);
      isValidPurchase = googleResponse.data.purchaseState === 0;
      responseData = googleResponse.data;
    } else if (platform === "ios") {
      const result = await verifyAppleReceipt(purchaseToken);
      isValidPurchase = result.valid;
      responseData = result.data || result.error;
    }

    if (isValidPurchase) {
      await admin.firestore().collection("users").doc(userId).update({isPremium: true});
      return res.json({success: true, message: "Premium doğrulandı!", data: responseData});
    } else {
      return res.status(403).json({success: false, message: "Satın alma geçersiz.", data: responseData});
    }
  } catch (error) {
    console.error("Purchase verification error:", error);
    return res.status(500).json({success: false, message: "Satın alma doğrulanamadı.", error: error.message});
  }
});


exports.verifyPurchase = functions.https.onRequest(app);
