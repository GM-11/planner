import {
  GoogleSignin,
  GoogleSigninButton,
  statusCodes,
} from "@react-native-google-signin/google-signin";
import { supabase } from "../utils/supabase";

export default function GoogleAuthButton() {
  GoogleSignin.configure({
    scopes: ["https://www.googleapis.com/auth/drive.readonly"],
    webClientId:
      "77416659252-nl9fcse96p6pb3k2i2lhij2rojs2c1e4.apps.googleusercontent.com",
  });

  async function googleLogin() {
    try {
      await GoogleSignin.hasPlayServices();
      const userInfo = await GoogleSignin.signIn();
      const { error, data } = await supabase.auth.signInWithIdToken({
        provider: "google",
        token: userInfo.data?.idToken!,
      });
      if (error) throw error;
      console.log("Signed in!");
    } catch (error: any) {
      if (error.code === statusCodes.SIGN_IN_CANCELLED) {
      } else if (error.code === statusCodes.IN_PROGRESS) {
      } else if (error.code === statusCodes.PLAY_SERVICES_NOT_AVAILABLE) {
      } else {
        throw error;
      }
    }
  }

  return (
    <GoogleSigninButton
      size={GoogleSigninButton.Size.Wide}
      color={GoogleSigninButton.Color.Dark}
      onPress={googleLogin}
    />
  );
}
