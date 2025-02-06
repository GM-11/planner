import { DateNavigator } from "@/components/DateNavigator";
import { useState } from "react";
import { View, Text } from "react-native";

export default function Calendar() {
  const [selectedDate, setSelectedDate] = useState(new Date());

  return (
    <View className="flex-1 bg-white">
      {/* <DateNavigator
        selectedDate={selectedDate}
        onDateChange={setSelectedDate}
      />
      <Text className="text-gray-500 text-center mt-4">Calendar Screen</Text> */}
    </View>
  );
}
