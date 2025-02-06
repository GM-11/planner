import { Ionicons } from "@expo/vector-icons";
import { format, addDays } from "date-fns";
import { View, Text, TouchableOpacity } from "react-native";

interface DateNavigatorProps {
  selectedDate: Date;
  onDateChange: (newDate: Date) => void;
}

export function DateNavigator({
  selectedDate,
  onDateChange,
}: DateNavigatorProps) {
  const handleDateChange = (direction: "prev" | "next") => {
    const newDate =
      direction === "next"
        ? addDays(selectedDate, 1)
        : addDays(selectedDate, -1);
    onDateChange(newDate);
  };

  return (
    <View className="flex-row items-center justify-between p-4 border-b border-gray-200">
      <TouchableOpacity
        onPress={() => handleDateChange("prev")}
        className="p-2"
      >
        <Ionicons name="chevron-back" size={24} color="black" />
      </TouchableOpacity>
      <Text className="text-xl font-bold">
        {format(selectedDate, "MMMM d, yyyy")}
      </Text>
      <TouchableOpacity
        onPress={() => handleDateChange("next")}
        className="p-2"
      >
        <Ionicons name="chevron-forward" size={24} color="black" />
      </TouchableOpacity>
    </View>
  );
}
