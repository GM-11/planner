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
import {
  importanceColors,
  importanceLevels,
  toTitleCase,
} from "@/utils/constants";
import { Ionicons } from "@expo/vector-icons";

const screenWidth = Dimensions.get("window").width;

const styles = {
  headerBg: "bg-primary-800 rounded-b-[30px]",
  cardBg: "bg-white rounded-xl shadow-sm",
  statCard: "bg-primary-50 p-4 rounded-xl shadow-sm",
};

const chartConfig = {
  backgroundGradientFrom: "#ffffff",
  backgroundGradientTo: "#ffffff",
  color: (opacity = 1) => `rgba(126, 34, 206, ${opacity})`, // primary-700
  strokeWidth: 2,
  barPercentage: 0.5,
  useShadowColorFromDataset: false,
  decimalPlaces: 0,
  propsForLabels: {
    fontFamily: "Poppins_400Regular",
    fontSize: 8, // Smaller font size
    rotation: 90, // Vertical rotation
  },
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
  const [timeFilter, setTimeFilter] = useState<"daily" | "week" | "month">(
    "daily",
  );
  const [chartType, setChartType] = useState<"circular" | "line">("circular");

  const performanceMetrics = useMemo(() => {
    const cutoffDate =
      timeFilter === "daily"
        ? new Date() // Today only
        : timeFilter === "week"
          ? subDays(new Date(), 7)
          : subDays(new Date(), 30);

    const filteredTasks = Object.entries(tasksByDate)
      .filter(([date]) => {
        const taskDate = new Date(date);
        if (timeFilter === "daily") {
          // For daily, only include today's tasks
          return (
            format(taskDate, "yyyy-MM-dd") === format(new Date(), "yyyy-MM-dd")
          );
        }
        return taskDate >= cutoffDate;
      })
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

    const getDateInterval = (timeFilter: "daily" | "week" | "month") => {
      switch (timeFilter) {
        case "daily":
          return 1;
        case "week":
          return 1;
        case "month":
          return 3;
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
  ).map(([importance, count]) => {
    // Get the index of the importance level
    const importanceIndex = Number(importance); // Since importance is now a number

    return {
      name: importanceLevels[importanceIndex], // Get the name from importanceLevels
      population: count,
      color: importanceColors[importanceIndex], // Get the color from importanceColors
      legendFontColor: "#475569", // text-slate-600 for better readability
      legendFontSize: 12,
      percentage:
        performanceMetrics.totalTasks > 0
          ? ((count / performanceMetrics.totalTasks) * 100).toFixed(0)
          : "0",
    };
  });

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
    <ScrollView className="flex-1 bg-primary-50">
      {/* Header Section */}
      <View className={styles.headerBg}>
        <View className="p-6">
          <Text className="text-primary-50 font-poppins_600 text-2xl mb-2">
            Profile
          </Text>
          <Text className="text-primary-200 font-poppins_400">
            {user?.email}
          </Text>
        </View>
      </View>

      <View className="p-4 -mt-4">
        {/* Time Filter Buttons */}
        <View className="bg-white rounded-2xl p-2 flex-row justify-around mb-6 shadow-sm">
          {(chartType === "circular"
            ? ["daily", "week", "month"]
            : ["week", "month"]
          ).map((filter) => (
            <TouchableOpacity
              key={filter}
              onPress={() =>
                setTimeFilter(filter as "daily" | "week" | "month")
              }
              className={`px-4 py-2 rounded-xl ${
                timeFilter === filter ? "bg-primary-600" : "bg-primary-50"
              }`}
            >
              <Text
                className={`${
                  timeFilter === filter ? "text-white" : "text-primary-600"
                } capitalize font-poppins_500`}
              >
                {filter}
              </Text>
            </TouchableOpacity>
          ))}
        </View>

        {/* Chart Type Toggle */}
        <View className="bg-white rounded-2xl p-2 flex-row justify-around mb-6 shadow-sm">
          {["circular", "line"].map((type) => (
            <TouchableOpacity
              key={type}
              onPress={() => {
                if (timeFilter === "daily" && type === "line") {
                  setTimeFilter("week");
                }
                setChartType(type as "circular" | "line");
              }}
              className={`px-4 py-2 rounded-xl ${
                chartType === type ? "bg-primary-600" : "bg-primary-50"
              }`}
            >
              <View className="flex-row items-center justify-center">
                {type === "circular" ? (
                  <Ionicons
                    name="pie-chart"
                    size={18}
                    color={chartType === type ? "#ffffff" : "#7e22ce"}
                  />
                ) : (
                  <Ionicons
                    name="stats-chart"
                    size={18}
                    color={chartType === type ? "#ffffff" : "#7e22ce"}
                  />
                )}
              </View>
            </TouchableOpacity>
          ))}
        </View>

        {/* Performance Visualization */}
        <View className={`${styles.cardBg} p-6 mb-6`}>
          <Text className="text-primary-800 font-poppins_600 text-lg mb-4 text-center">
            Performance Overview
          </Text>
          {chartType === "circular" ? (
            <View className="items-center">
              <CircularProgress
                value={performanceMetrics.averageCompletionRate}
                radius={80}
                duration={2000}
                progressValueColor={"#1e293b"}
                maxValue={100}
                title={
                  timeFilter === "daily"
                    ? "Today"
                    : toTitleCase(timeFilter + "ly")
                }
                titleColor={"#7e22ce"}
                titleStyle={{
                  fontFamily: "Poppins_600SemiBold",
                  fontSize: 16,
                }}
                inActiveStrokeColor={"#7e22ce"}
                inActiveStrokeOpacity={0.2}
                activeStrokeColor={"#7e22ce"}
                activeStrokeWidth={15}
                inActiveStrokeWidth={15}
              />
            </View>
          ) : (
            <LineChart
              data={lineChartData}
              width={screenWidth - 64}
              height={220}
              chartConfig={chartConfig}
              bezier
              style={{
                marginVertical: 8,
                borderRadius: 16,
              }}
            />
          )}
        </View>

        {/* Task Distribution */}
        <View className={`${styles.cardBg} p-6 mb-6`}>
          <Text className="text-primary-800 font-poppins_600 text-lg mb-4 text-center">
            Task Distribution
          </Text>
          {performanceMetrics.totalTasks > 0 ? (
            <>
              <PieChart
                data={pieChartData}
                width={screenWidth - 64}
                height={200}
                chartConfig={{
                  ...chartConfig,
                  color: (opacity = 1) => `rgba(126, 34, 206, ${opacity})`,
                }}
                accessor="population"
                backgroundColor="transparent"
                paddingLeft="15"
                absolute
                hasLegend={false} // Remove default legend as we're using custom legend
              />
              {/* Custom Legend */}
              <View className="flex-row flex-wrap justify-around mt-4">
                {pieChartData.map((data) => (
                  <View key={data.name} className="items-center p-2">
                    <View className="flex-row items-center">
                      <View
                        className="w-3 h-3 rounded-full mr-2"
                        style={{ backgroundColor: data.color }}
                      />
                      <Text className="capitalize font-poppins_500 text-primary-700">
                        {data.name.replace("-", " ")}
                      </Text>
                    </View>
                    <Text className="font-poppins_400 text-primary-400">
                      {data.percentage}%
                    </Text>
                  </View>
                ))}
              </View>
            </>
          ) : (
            <Text className="text-primary-400 font-poppins_500 text-center">
              No tasks available
            </Text>
          )}
        </View>

        {/* Summary Stats */}
        <View className={`${styles.cardBg} p-6 mb-6`}>
          <Text className="text-primary-800 font-poppins_600 text-lg mb-4">
            Summary
          </Text>
          <View className="flex-row justify-between">
            <View className="items-center bg-primary-50 p-4 rounded-xl flex-1 mr-2">
              <Text className="text-primary-600 font-poppins_500">
                Total Tasks
              </Text>
              <Text className="text-2xl font-poppins_700 text-primary-800">
                {performanceMetrics.totalTasks}
              </Text>
            </View>
            <View className="items-center bg-primary-50 p-4 rounded-xl flex-1 ml-2">
              <Text className="text-primary-600 font-poppins_500">
                Completed
              </Text>
              <Text className="text-2xl font-poppins_700 text-primary-800">
                {performanceMetrics.completedTasks}
              </Text>
            </View>
          </View>
        </View>

        {/* Sign Out Button */}
        <TouchableOpacity
          onPress={signOut}
          className="bg-primary-600 p-4 rounded-xl mb-6"
        >
          <Text className="text-white text-center font-poppins_600">
            Sign Out
          </Text>
        </TouchableOpacity>
      </View>
    </ScrollView>
  );
}
