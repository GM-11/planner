import { View, Text, TouchableOpacity } from "react-native";
import { useAuth } from "../../hooks/useAuth";
import { Link } from "expo-router";

export default function Home() {
  const { user, signOut } = useAuth();

  return (
    <View className="flex-1 p-4 bg-white">
      <Text className="text-xl">Welcome {user?.email}</Text>
      <TouchableOpacity
        onPress={signOut}
        className="bg-red-500 p-2 rounded mt-4"
      >
        <Text className="text-white text-center">Sign Out</Text>
      </TouchableOpacity>
      <Link href="/(app)/some" className="bg-blue-500 p-2 rounded mt-4">
        <Text>Go to page</Text>
      </Link>
    </View>
  );
}
