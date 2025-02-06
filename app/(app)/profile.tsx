import { View, Text, TouchableOpacity } from "react-native";
import { useAuth } from "../../hooks/useAuth";

export default function Profile() {
  const { user, signOut } = useAuth();

  return (
    <View className="flex-1 p-4 bg-white">
      <Text className="text-xl mb-4">Profile</Text>
      <Text className="mb-4">Email: {user?.email}</Text>
      <TouchableOpacity onPress={signOut} className="bg-red-500 p-2 rounded">
        <Text className="text-white text-center">Sign Out</Text>
      </TouchableOpacity>
    </View>
  );
}
