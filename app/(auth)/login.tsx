import React, { useState } from "react";
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  ActivityIndicator,
  Alert,
} from "react-native";
import { useAuth } from "../../hooks/useAuth";
import { Link, router } from "expo-router";
import { Ionicons } from "@expo/vector-icons";

export default function Login() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [showPassword, setShowPassword] = useState(false);

  const { signIn } = useAuth();

  const handleSignIn = async () => {
    if (!email || !password) {
      Alert.alert("Error", "Please fill in all fields");
      return;
    }

    try {
      setLoading(true);
      await signIn(email, password);
      router.replace("/(app)/tasks");
    } catch (error: any) {
      setLoading(false);
    }
  };

  return (
    <View className="flex-1 bg-primary-100">
      {/* Mobile Design */}
      <View className="lg:hidden flex-1">
        {/* Top Design Section */}
        <View className="h-2/5 bg-primary-800 rounded-b-[50px] justify-end pb-12 px-6">
          <Text className="text-primary-50 font-poppins_700 text-4xl mb-2">
            Welcome Back
          </Text>
          <Text className="text-primary-300 font-poppins_400 text-lg">
            Let's help you stay organized
          </Text>
        </View>

        {/* Login Form Section */}
        <View className="flex-1 px-6 pt-8">
          {/* Email Input */}
          <View className="mb-6">
            <Text className="text-primary-700 font-poppins_500 mb-2 ml-1">
              Email
            </Text>
            <View className="flex-row items-center bg-white rounded-2xl px-4 shadow-sm border border-primary-200">
              <Ionicons name="mail-outline" size={20} color="#475569" />
              <TextInput
                placeholder="Enter your email"
                value={email}
                onChangeText={setEmail}
                keyboardType="email-address"
                autoCapitalize="none"
                className="flex-1 p-4 font-poppins_400 text-primary-800 ml-2"
                placeholderTextColor="#94a3b8"
              />
            </View>
          </View>

          {/* Password Input */}
          <View className="mb-8">
            <Text className="text-primary-700 font-poppins_500 mb-2 ml-1">
              Password
            </Text>
            <View className="flex-row items-center bg-white rounded-2xl px-4 shadow-sm border border-primary-200">
              <Ionicons name="lock-closed-outline" size={20} color="#475569" />
              <TextInput
                placeholder="Enter your password"
                value={password}
                onChangeText={setPassword}
                secureTextEntry={!showPassword}
                className="flex-1 p-4 font-poppins_400 text-primary-800 ml-2"
                placeholderTextColor="#94a3b8"
              />
              <TouchableOpacity onPress={() => setShowPassword(!showPassword)}>
                <Ionicons
                  name={showPassword ? "eye-off-outline" : "eye-outline"}
                  size={20}
                  color="#475569"
                />
              </TouchableOpacity>
            </View>
          </View>

          {/* Forgot Password */}
          <TouchableOpacity className="items-end mb-8">
            <Text className="text-secondary-DEFAULT font-poppins_500">
              Forgot Password?
            </Text>
          </TouchableOpacity>

          {/* Sign In Button */}
          <TouchableOpacity
            onPress={handleSignIn}
            disabled={loading}
            className="bg-primary-600 py-4 rounded-2xl shadow-md active:bg-primary-700"
          >
            {loading ? (
              <ActivityIndicator color="white" />
            ) : (
              <Text className="text-white text-center font-poppins_600 text-lg">
                Sign In
              </Text>
            )}
          </TouchableOpacity>

          {/* Sign Up Link */}
          <View className="flex-row justify-center mt-8">
            <Text className="text-primary-400 font-poppins_400">
              Don't have an account?
            </Text>
            <Link href="/register" asChild>
              <TouchableOpacity>
                <Text className="text-primary-700 font-poppins_600 ml-1">
                  Sign Up
                </Text>
              </TouchableOpacity>
            </Link>
          </View>
        </View>
      </View>

      {/* Desktop Design */}
      <View className="hidden lg:flex flex-1 flex-row">
        {/* Left Panel */}
        <View className="w-1/2 bg-primary-800 justify-center items-center px-12">
          <View>
            <Text className="text-primary-50 font-poppins_700 text-5xl mb-4">
              Welcome Back
            </Text>
            <Text className="text-primary-300 font-poppins_400 text-xl">
              Let's help you stay organized
            </Text>
          </View>
        </View>

        {/* Right Panel */}
        <View className="w-1/2 justify-center px-16">
          <View className="max-w-md mx-auto w-full">
            {/* Email Input */}
            <View className="mb-6">
              <Text className="text-primary-700 font-poppins_500 mb-2 ml-1">
                Email
              </Text>
              <View className="flex-row items-center bg-white rounded-2xl px-4 shadow-sm border border-primary-200">
                <Ionicons name="mail-outline" size={20} color="#475569" />
                <TextInput
                  placeholder="Enter your email"
                  value={email}
                  onChangeText={setEmail}
                  keyboardType="email-address"
                  autoCapitalize="none"
                  className="flex-1 p-4 font-poppins_400 text-primary-800 ml-2"
                  placeholderTextColor="#94a3b8"
                />
              </View>
            </View>

            {/* Password Input */}
            <View className="mb-8">
              <Text className="text-primary-700 font-poppins_500 mb-2 ml-1">
                Password
              </Text>
              <View className="flex-row items-center bg-white rounded-2xl px-4 shadow-sm border border-primary-200">
                <Ionicons
                  name="lock-closed-outline"
                  size={20}
                  color="#475569"
                />
                <TextInput
                  placeholder="Enter your password"
                  value={password}
                  onChangeText={setPassword}
                  secureTextEntry={!showPassword}
                  className="flex-1 p-4 font-poppins_400 text-primary-800 ml-2"
                  placeholderTextColor="#94a3b8"
                />
                <TouchableOpacity
                  onPress={() => setShowPassword(!showPassword)}
                >
                  <Ionicons
                    name={showPassword ? "eye-off-outline" : "eye-outline"}
                    size={20}
                    color="#475569"
                  />
                </TouchableOpacity>
              </View>
            </View>

            {/* Forgot Password */}
            <TouchableOpacity className="items-end mb-8">
              <Text className="text-secondary-DEFAULT font-poppins_500">
                Forgot Password?
              </Text>
            </TouchableOpacity>

            {/* Sign In Button */}
            <TouchableOpacity
              onPress={handleSignIn}
              disabled={loading}
              className="bg-primary-600 py-4 rounded-2xl shadow-md active:bg-primary-700"
            >
              {loading ? (
                <ActivityIndicator color="white" />
              ) : (
                <Text className="text-white text-center font-poppins_600 text-lg">
                  Sign In
                </Text>
              )}
            </TouchableOpacity>

            {/* Sign Up Link */}
            <View className="flex-row justify-center mt-8">
              <Text className="text-primary-400 font-poppins_400">
                Don't have an account?
              </Text>
              <Link href="/register" asChild>
                <TouchableOpacity>
                  <Text className="text-primary-700 font-poppins_600 ml-1">
                    Sign Up
                  </Text>
                </TouchableOpacity>
              </Link>
            </View>
          </View>
        </View>
      </View>
    </View>
  );
}
