import { initializeApp } from "@react-native-firebase/app";

const firebaseConfig = {
  apiKey: "AIzaSyBFOk456UlQeUiuKgp5TuD3l186eGZtFVc",
  authDomain: "n-a-c-39adb.firebaseapp.com",
  databaseURL: "https://n-a-c-39adb.firebaseio.com",
  projectId: "n-a-c-39adb",
  storageBucket: "n-a-c-39adb.appspot.com",
  messagingSenderId: "516911058445",
  appId: "1:516911058445:android:7be2a656a5c9a298d38f44",
};

export const initializeFirebase = () => {
  try {
    initializeApp(firebaseConfig);
  } catch (error) {
    console.log("Firebase initialization error:", error);
  }
};
