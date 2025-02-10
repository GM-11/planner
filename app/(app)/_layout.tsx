import { Tabs } from "expo-router";
import { useAuth } from "../../hooks/useAuth";
import { Redirect } from "expo-router";
import { View, ActivityIndicator } from "react-native";
import { Ionicons } from "@expo/vector-icons";

export default function AppLayout() {
  const { user, loading } = useAuth();

  if (loading) {
    return (
      <View className="flex-1 justify-center items-center bg-primary-50">
        <ActivityIndicator size="large" color="#7e22ce" />
      </View>
    );
  }

  if (!user) {
    return <Redirect href="/login" />;
  }

  return (
    <Tabs
      screenOptions={{
        tabBarActiveTintColor: "#ffffff",
        tabBarInactiveTintColor: "#94a3b8",
        headerShown: false,
        tabBarStyle: {
          backgroundColor: "#1e293b", // slate-800
          borderTopWidth: 0,
          height: 60,
          paddingHorizontal: 20,
          shadowColor: "#000",
          shadowOffset: {
            width: 0,
            height: -4,
          },
          shadowOpacity: 0.15,
          shadowRadius: 12,
        },
        tabBarItemStyle: {
          height: 60,
          padding: 8,
        },
        tabBarLabelStyle: {
          fontFamily: "Poppins_500Medium",
          fontSize: 12,
          marginTop: 0,
        },
      }}
    >
      <Tabs.Screen
        name="tasks"
        options={{
          title: "Tasks",
          tabBarIcon: ({ focused, size }) => (
            <View
              className={`p-1.5 h-10 w-10 items-center rounded-xl ${focused ? "bg-primary-600" : ""}`}
            >
              <Ionicons
                name={focused ? "checkbox" : "checkbox-outline"}
                size={24}
                color={focused ? "#ffffff" : "#94a3b8"}
              />
            </View>
          ),
          tabBarLabel: ({ focused }) => (
            <View className={focused ? "" : "opacity-0"}>
              <View className="h-1 w-1 rounded-full bg-white mx-auto mt-2" />
            </View>
          ),
        }}
      />
      <Tabs.Screen
        name="calendar"
        options={{
          title: "Calendar",
          tabBarIcon: ({ focused, size }) => (
            <View
              className={`p-1.5 h-10 w-10 items-center rounded-xl ${focused ? "bg-primary-600" : ""}`}
            >
              <Ionicons
                name={focused ? "calendar" : "calendar-outline"}
                size={24}
                color={focused ? "#ffffff" : "#94a3b8"}
              />
            </View>
          ),
          tabBarLabel: ({ focused }) => (
            <View className={focused ? "" : "opacity-0"}>
              <View className="h-1 w-1 rounded-full bg-white mx-auto mt-2" />
            </View>
          ),
        }}
      />
      <Tabs.Screen
        name="profile"
        options={{
          title: "Profile",
          tabBarIcon: ({ focused, size }) => (
            <View
              className={`p-1.5 h-10 w-10 items-center rounded-xl ${focused ? "bg-primary-600" : ""}`}
            >
              <Ionicons
                name={focused ? "person" : "person-outline"}
                size={24}
                color={focused ? "#ffffff" : "#94a3b8"}
              />
            </View>
          ),
          tabBarLabel: ({ focused }) => (
            <View className={focused ? "" : "opacity-0"}>
              <View className="h-1 w-1 rounded-full bg-white mx-auto mt-2" />
            </View>
          ),
        }}
      />
    </Tabs>
  );
}
