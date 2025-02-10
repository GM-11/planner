import { View } from "react-native";
import { Shimmer } from "./Shimmer";

export const LoadingIndicator = () => {
  const TaskShimmerItem = () => (
    <View className="mb-3 bg-white rounded-xl shadow-sm overflow-hidden">
      <View className="flex-row items-center p-4">
        {/* Checkbox Shimmer */}
        <View className="mr-3">
          <Shimmer width={24} height={24} borderRadius={12} />
        </View>

        {/* Content Area */}
        <View className="flex-1">
          {/* Task Title */}
          <Shimmer
            width={180}
            height={20}
            borderRadius={4}
            style={{ marginBottom: 8 }}
          />

          {/* Time */}
          <Shimmer width={120} height={16} borderRadius={4} />
        </View>

        {/* Delete Button */}
        <View className="ml-2">
          <Shimmer width={24} height={24} borderRadius={12} />
        </View>
      </View>
    </View>
  );

  return (
    <View className="flex-1 px-4 pt-4">
      {/* Header Area */}
      <View className="mb-6">
        <View className="flex-row justify-between items-center">
          <Shimmer width={150} height={24} borderRadius={6} />
          <View className="flex-row space-x-2">
            <Shimmer width={80} height={32} borderRadius={16} />
            <Shimmer width={80} height={32} borderRadius={16} />
          </View>
        </View>
      </View>

      {/* Task List Shimmers */}
      {[1, 2, 3, 4, 5].map((item) => (
        <TaskShimmerItem key={item} />
      ))}
    </View>
  );
};
