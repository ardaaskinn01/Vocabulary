const functions = require("firebase-functions");
const admin = require("firebase-admin");
const axios = require("axios");

admin.initializeApp();

// 📌 **Satın alma doğrulama fonksiyonu**
exports.verifyPurchase = functions.https.onCall(async (data, context) => {
  const {userId, purchaseToken, platform} = data;

  if (!userId || !purchaseToken || !platform) {
    throw new functions.https.HttpsError("invalid-argument", "Eksik parametreler.");
  }

  try {
    let isValidPurchase = false;

    if (platform === "android") {
      // 📌 **Google Play satın alma doğrulama URL'si**
      const googleApiUrl = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/com.aasoft.ingilizce/purchases/subscriptions/premiumaccess1/tokens/${purchaseToken}`;

      // 📌 Google API Key'i burada kullanmalısın
      const googleApiKey = "AIzaSyBSxaYGFhx2f9FX3htIcMyQlP_2oxBmzyo";

      const googleResponse = await axios.get(`${googleApiUrl}?key=${googleApiKey}`);
      isValidPurchase = googleResponse.data.purchaseState === 0; // 0 = Aktif abonelik
    } else if (platform === "ios") {
      // 📌 **App Store satın alma doğrulama URL'si**
      const appleApiUrl = "https://buy.itunes.apple.com/verifyReceipt";

      const appleResponse = await axios.post(appleApiUrl, {
        "receipt-data": purchaseToken,
        "password": "6f89c9b9893b4689a79e4d35b4169ad6",
      });

      isValidPurchase = appleResponse.data.status === 0; // 0 = Geçerli işlem
    }

    if (isValidPurchase) {
      // 📌 Kullanıcıyı Premium olarak işaretle
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
