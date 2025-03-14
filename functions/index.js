const functions = require("firebase-functions");
const admin = require("firebase-admin");
const axios = require("axios");

admin.initializeApp();

// Firebase gizli değişkenleri al
const googleApiKey = functions.config().google.api_key;
const appleSharedSecret = functions.config().apple.shared_secret;

exports.verifyPurchase = functions.https.onCall(async (data, context) => {
  const {userId, purchaseToken, platform} = data;

  if (!userId || !purchaseToken || !platform) {
    throw new functions.https.HttpsError("invalid-argument", "Eksik parametreler.");
  }

  try {
    let isValidPurchase = false;

    if (platform === "android") {
      const googleApiUrl = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/com.aasoft.ingilizce/purchases/subscriptions/premiumaccess1/tokens/${purchaseToken}`;

      const googleResponse = await axios.get(`${googleApiUrl}?key=${googleApiKey}`);
      isValidPurchase = googleResponse.data.purchaseState === 0;
    } else if (platform === "ios") {
      const appleApiUrl = "https://buy.itunes.apple.com/verifyReceipt";

      const appleResponse = await axios.post(appleApiUrl, {
        "receipt-data": purchaseToken,
        "password": appleSharedSecret,
      });

      isValidPurchase = appleResponse.data.status === 0;
    }

    if (isValidPurchase) {
      await admin.firestore().collection("users").doc(userId).update({isPremium: true});
      return {success: true, message: "Premium doğrulandı!"};
    } else {
      throw new functions.https.HttpsError("permission-denied", "Satın alma geçersiz.");
    }
  } catch (error) {
    console.error("Doğrulama hatası:", error);
    throw new functions.https.HttpsError("internal", "Satın alma doğrulanamadı.");
  }
});
