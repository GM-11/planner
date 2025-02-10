import {
  View,
  Text,
  TouchableOpacity,
  Dimensions,
  ScrollView,
} from "react-native";
import { useAuth } from "../../hooks/useAuth";
import { useTaskContext } from "@/context/TaskContext";
import { useMemo, useState } from "react";
import { LineChart, PieChart } from "react-native-chart-kit";
import { format, subDays, eachDayOfInterval } from "date-fns";
import CircularProgress from "react-native-circular-progress-indicator";

const screenWidth = Dimensions.get("window").width;

const chartConfig = {
  backgroundGradientFrom: "#ffffff",
  backgroundGradientTo: "#ffffff",
  color: (opacity = 1) => `rgba(0, 0, 0, ${opacity})`,
  strokeWidth: 2,
  barPercentage: 0.5,
  useShadowColorFromDataset: false,
  decimalPlaces: 0,
};

const chartColors = new Map([
  ["very-important", "#ef4444"],
  ["important", "#f97316"],
  ["mildly-important", "#eab308"],
  ["less-important", "#22c55e"],
]);

export default function Profile() {
  const { user, signOut } = useAuth();
  const { tasksByDate } = useTaskContext();
  const [timeFilter, setTimeFilter] = useState<"week" | "month" | "all">(
    "week",
  );
  const [chartType, setChartType] = useState<"circular" | "line">("circular");

  const performanceMetrics = useMemo(() => {
    const cutoffDate =
      timeFilter === "week"
        ? subDays(new Date(), 7)
        : timeFilter === "month"
          ? subDays(new Date(), 30)
          : new Date(0);

    const filteredTasks = Object.entries(tasksByDate)
      .filter(([date]) => new Date(date) >= cutoffDate)
      .flatMap(([_, tasks]) => tasks);

    const totalTasks = filteredTasks.length;
    const completedTasks = filteredTasks.filter(
      (task) => task.completed,
    ).length;
    const completionRate =
      totalTasks > 0
        ? parseFloat(((completedTasks / totalTasks) * 100).toFixed(1))
        : 0;

    // Calculate importance distribution
    const importanceDistribution = filteredTasks.reduce(
      (acc: Record<string, number>, task) => {
        acc[task.importance] = (acc[task.importance] || 0) + 1;
        return acc;
      },
      {},
    );

    const getDateInterval = (timeFilter: "week" | "month" | "all") => {
      switch (timeFilter) {
        case "week":
          return 1;
        case "month":
          return 3;
        case "all":
          return 7;
      }
    };

    // Daily completion data
    const dailyCompletion = eachDayOfInterval({
      start: cutoffDate,
      end: new Date(),
    }).reduce(
      (
        acc: Array<{ date: string; completed: number; total: number }>,
        date,
        index,
      ) => {
        const interval = getDateInterval(timeFilter);
        const dateStr = format(date, "yyyy-MM-dd");
        const dayTasks = tasksByDate[dateStr] || [];
        const completed = dayTasks.filter((task) => task.completed).length;
        const total = dayTasks.length;

        if (index % interval === 0) {
          acc.push({
            date: format(date, "MMM d"),
            completed,
            total,
          });
        }
        return acc;
      },
      [],
    );

    // Calculate average completion rates
    const averageCompletion = dailyCompletion.reduce(
      (acc, day) => {
        if (day.total > 0) {
          acc.totalRate += (day.completed / day.total) * 100;
          acc.count += 1;
        }
        return acc;
      },
      { totalRate: 0, count: 0 },
    );

    const averageCompletionRate =
      averageCompletion.count > 0
        ? averageCompletion.totalRate / averageCompletion.count
        : 0;

    return {
      totalTasks,
      completedTasks,
      completionRate,
      importanceDistribution,
      dailyCompletion,
      averageCompletionRate,
    };
  }, [tasksByDate, timeFilter]);

  // Prepare pie chart data
  const pieChartData = Object.entries(
    performanceMetrics.importanceDistribution,
  ).map(([importance, count]) => ({
    name: importance,
    population: count,
    color: chartColors.get(importance) || "#000",
    legendFontColor: "#7F7F7F",
    legendFontSize: 12,
    percentage:
      performanceMetrics.totalTasks > 0
        ? ((count / performanceMetrics.totalTasks) * 100).toFixed(0)
        : "0",
  }));

  // Prepare line chart data
  const lineChartData = {
    labels: performanceMetrics.dailyCompletion.map((item) => item.date),
    datasets: [
      {
        data: performanceMetrics.dailyCompletion.map((item) =>
          item.total > 0 ? (item.completed / item.total) * 100 : 0,
        ),
        color: (opacity = 1) => `rgba(54, 162, 235, ${opacity})`,
        strokeWidth: 2,
      },
    ],
  };

  return (
    <ScrollView className="flex-1 bg-white">
      <View className="p-4">
        <Text className="text-xl mb-4">Profile</Text>
        <Text className="mb-4">Email: {user?.email}</Text>

        {/* Time Filter Buttons */}
        <View className="flex-row justify-around mb-4">
          {["week", "month", "all"].map((filter) => (
            <TouchableOpacity
              key={filter}
              onPress={() => setTimeFilter(filter as "week" | "month" | "all")}
              className={`px-4 py-2 rounded ${
                timeFilter === filter ? "bg-blue-500" : "bg-gray-200"
              }`}
            >
              <Text
                className={`${
                  timeFilter === filter ? "text-white" : "text-gray-600"
                } capitalize`}
              >
                {filter}
              </Text>
            </TouchableOpacity>
          ))}
        </View>

        {/* Chart Type Toggle */}
        <View className="flex-row justify-around mb-4">
          {["circular", "line"].map((type) => (
            <TouchableOpacity
              key={type}
              onPress={() => setChartType(type as "circular" | "line")}
              className={`px-4 py-2 rounded ${
                chartType === type ? "bg-blue-500" : "bg-gray-200"
              }`}
            >
              <Text
                className={`${
                  chartType === type ? "text-white" : "text-gray-600"
                } capitalize`}
              >
                {type} View
              </Text>
            </TouchableOpacity>
          ))}
        </View>

        {/* Performance Visualization */}
        <View className="mb-6">
          <Text className="text-lg font-semibold mb-2 text-center">
            Performance Overview
          </Text>
          {chartType === "circular" ? (
            <View className="items-center">
              <CircularProgress
                value={performanceMetrics.averageCompletionRate}
                radius={80}
                duration={2000}
                progressValueColor={"#333"}
                maxValue={100}
                title={`${timeFilter} average`}
                titleColor={"#333"}
                titleStyle={{ fontWeight: "bold" }}
                inActiveStrokeColor={"#2ecc71"}
                inActiveStrokeOpacity={0.2}
                activeStrokeColor={"#2ecc71"}
                activeStrokeWidth={15}
                inActiveStrokeWidth={15}
              />
            </View>
          ) : (
            <LineChart
              data={lineChartData}
              width={screenWidth - 32}
              height={220}
              chartConfig={{
                ...chartConfig,
                propsForLabels: {
                  fontSize: 10,
                  rotation: timeFilter === "week" ? 0 : 45,
                },
              }}
              bezier
              style={{
                marginVertical: 8,
                borderRadius: 16,
              }}
            />
          )}
        </View>

        {/* Task Distribution Pie Chart */}
        <View className="mb-6">
          <Text className="text-lg font-semibold mb-2 text-center">
            Task Distribution
          </Text>
          {performanceMetrics.totalTasks > 0 ? (
            <>
              <PieChart
                data={pieChartData}
                width={screenWidth - 32}
                height={200}
                chartConfig={chartConfig}
                accessor="population"
                backgroundColor="transparent"
                paddingLeft="15"
                absolute
              />
              {/* Custom Legend */}
              <View className="flex-row justify-around mt-4">
                {pieChartData.map((data) => (
                  <View key={data.name} className="items-center">
                    <View className="flex-row items-center">
                      <View
                        style={{
                          width: 12,
                          height: 12,
                          backgroundColor: data.color,
                          borderRadius: 6,
                          marginRight: 4,
                        }}
                      />
                      <Text className="capitalize">{data.name}</Text>
                    </View>
                    <Text className="text-gray-600">{data.percentage}%</Text>
                  </View>
                ))}
              </View>
            </>
          ) : (
            <Text className="text-gray-500 text-center">
              No tasks available
            </Text>
          )}
        </View>

        {/* Summary Stats */}
        <View className="bg-gray-100 p-4 rounded-lg mb-6">
          <Text className="text-lg font-semibold mb-2">Summary</Text>
          <View className="flex-row justify-between">
            <View className="items-center">
              <Text className="text-gray-600">Total Tasks</Text>
              <Text className="text-2xl font-bold">
                {performanceMetrics.totalTasks}
              </Text>
            </View>
            <View className="items-center">
              <Text className="text-gray-600">Completed</Text>
              <Text className="text-2xl font-bold">
                {performanceMetrics.completedTasks}
              </Text>
            </View>
          </View>
        </View>

        <TouchableOpacity onPress={signOut} className="bg-red-500 p-2 rounded">
          <Text className="text-white text-center">Sign Out</Text>
        </TouchableOpacity>
      </View>
    </ScrollView>
  );
}
