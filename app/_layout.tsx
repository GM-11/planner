import { AuthProvider } from "../context/AuthContext";
import { Stack } from "expo-router";
import "../global.css";
import { TaskProvider } from "@/context/TaskContext";

export default function RootLayout() {
  return (
    <AuthProvider>
      <TaskProvider>
        <Stack screenOptions={{ headerShown: false }} />
      </TaskProvider>
    </AuthProvider>
  );
}
