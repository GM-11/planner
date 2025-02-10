import { Ionicons } from "@expo/vector-icons";
import { format, addDays, isSameDay } from "date-fns";
import { View, Text, TouchableOpacity } from "react-native";

interface DateNavigatorProps {
  selectedDate: Date;
  onDateChange: (newDate: Date) => void;
  variant?: "light" | "dark"; // Add variant prop for flexibility
}

export function DateNavigator({
  selectedDate,
  onDateChange,
  variant = "dark", // Default to dark variant
}: DateNavigatorProps) {
  const handleDateChange = (direction: "prev" | "next") => {
    const newDate =
      direction === "next"
        ? addDays(selectedDate, 1)
        : addDays(selectedDate, -1);
    onDateChange(newDate);
  };

  const isToday = isSameDay(selectedDate, new Date());

  // Define color classes based on variant
  const textColorClass =
    variant === "dark" ? "text-primary-50" : "text-primary-800";
  const secondaryTextColorClass =
    variant === "dark" ? "text-primary-200" : "text-primary-600";
  const buttonBgClass =
    variant === "dark" ? "bg-primary-700/30" : "bg-primary-100";
  const iconColor = variant === "dark" ? "#f1f5f9" : "#1e293b";

  return (
    <View className="px-6 py-4">
      <View className="flex-row items-center justify-between">
        <TouchableOpacity
          onPress={() => handleDateChange("prev")}
          className={`w-10 h-10 rounded-full items-center justify-center ${buttonBgClass}`}
        >
          <Ionicons name="chevron-back" size={24} color={iconColor} />
        </TouchableOpacity>

        <View className="items-center">
          <View className="flex-row items-center space-x-2">
            <Text className={`font-poppins_600 text-lg ${textColorClass}`}>
              {format(selectedDate, "MMMM d, yyyy")}
            </Text>
            {isToday && (
              <View className="bg-primary-600 px-2 py-0.5 rounded-full ml-2">
                <Text className="text-primary-50 font-poppins_500 text-xs">
                  Today
                </Text>
              </View>
            )}
          </View>
          <Text
            className={`font-poppins_400 text-sm mt-1 ${secondaryTextColorClass}`}
          >
            {format(selectedDate, "EEEE")}
          </Text>
        </View>

        <TouchableOpacity
          onPress={() => handleDateChange("next")}
          className={`w-10 h-10 rounded-full items-center justify-center ${buttonBgClass}`}
        >
          <Ionicons name="chevron-forward" size={24} color={iconColor} />
        </TouchableOpacity>
      </View>
    </View>
  );
}
