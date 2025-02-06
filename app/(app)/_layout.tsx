import { Stack } from "expo-router";
import { useAuth } from "../../hooks/useAuth";
import { Redirect } from "expo-router";
import { View, ActivityIndicator } from "react-native";

export default function AppLayout() {
  const { user, loading } = useAuth();

  if (loading) {
    return (
      <View className="flex-1 justify-center items-center">
        <ActivityIndicator size="large" color="#0000ff" />
      </View>
    );
  }

  if (!user) {
    return <Redirect href="/login" />;
  }

  return (
    <Stack screenOptions={{ headerShown: false }}>
      <Stack.Screen name="home" />
      <Stack.Screen name="some" />
    </Stack>
  );
}
