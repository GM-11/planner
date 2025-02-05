import GoogleAuthButton from "@/components/GoogleAuth";
import { supabase } from "@/utils/supabase";
import { Alert, Text, View, Button, Pressable } from "react-native";

export default function Index() {
  async function signUpWithGoogle() {
    try {
      const res = await supabase.auth.signInWithOAuth({ provider: "google" });
      console.log(res);
    } catch (err) {
      console.log(err);
    }
  }
  return (
    <View className="flex-1 items-center justify-center gap-y-2">
      <Pressable onPress={signUpWithGoogle}>
        <Text>Sign Up with google</Text>

        {/* <GoogleAuthButton /> */}
      </Pressable>
    </View>
  );
}
