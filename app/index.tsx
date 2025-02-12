import { Redirect } from "expo-router";
import { useAuth } from "../hooks/useAuth";
import { View, ActivityIndicator, Platform } from "react-native";
import * as Notifications from "expo-notifications";
import { useEffect, useRef, useState } from "react";
import { registerForPushNotificationsAsync } from "@/utils/constants";
import { initializeFirebase } from "@/utils/fireabseConfig";

export default function Index() {
  const { user, loading } = useAuth();
  const notificationListener = useRef<Notifications.EventSubscription>();
  const responseListener = useRef<Notifications.EventSubscription>();

  useEffect(() => {
    initializeFirebase();

    Notifications.setNotificationHandler({
      handleNotification: async () => ({
        shouldShowAlert: true,
        shouldPlaySound: true,
        shouldSetBadge: true,
      }),
    });

    registerForPushNotificationsAsync();

    responseListener.current =
      Notifications.addNotificationResponseReceivedListener((response) => {
        console.log(response);
      });

    return () => {
      notificationListener.current &&
        Notifications.removeNotificationSubscription(
          notificationListener.current,
        );
      responseListener.current &&
        Notifications.removeNotificationSubscription(responseListener.current);
    };
  }, []);

  if (loading) {
    return (
      <View className="flex-1 justify-center items-center">
        <ActivityIndicator size="large" color="#64748b" />
      </View>
    );
  }

  console.log(user);

  if (!user) {
    return <Redirect href="/(auth)/register" />;
  }

  return <Redirect href="/(app)/tasks" />;
}
