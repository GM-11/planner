import {
  View,
  Text,
  TouchableOpacity,
  Dimensions,
  ScrollView,
  Platform,
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

const screenWidth =
  Platform.OS === "web"
    ? Math.min(Dimensions.get("window").width, 1200)
    : Dimensions.get("window").width;

const styles = {
  headerBg: "bg-primary-800 rounded-b-[30px] lg:rounded-none",
  cardBg: "bg-white rounded-xl shadow-sm",
  statCard: "bg-primary-50 p-4 rounded-xl shadow-sm",
};

const desktopStyles = {
  container: "lg:flex-row lg:max-w-7xl lg:mx-auto",
  sidebar: "lg:w-[300px] lg:bg-primary-800 lg:min-h-screen lg:p-6",
  mainContent: "lg:p-8",
  chartContainer: "lg:grid lg:grid-cols-2 lg:gap-6",
};

const chartConfig = {
  backgroundGradientFrom: "#ffffff",
  backgroundGradientTo: "#ffffff",
  color: (opacity = 1) => `rgba(126, 34, 206, ${opacity})`,
  strokeWidth: 2,
  barPercentage: 0.5,
  useShadowColorFromDataset: false,
  decimalPlaces: 0,
  propsForLabels: {
    fontFamily: "Poppins_400Regular",
    fontSize: Platform.OS === "web" ? 12 : 8,
    rotation: 90,
  },
};
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
        ? new Date()
        : timeFilter === "week"
          ? subDays(new Date(), 7)
          : subDays(new Date(), 30);

    const filteredTasks = Object.entries(tasksByDate)
      .filter(([date]) => {
        const taskDate = new Date(date);
        if (timeFilter === "daily") {
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
    const importanceIndex = Number(importance);
    return {
      name: importanceLevels[importanceIndex],
      population: count,
      color: importanceColors[importanceIndex],
      legendFontColor: "#475569",
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

  const renderCharts = (isDesktop = false) => {
    const chartWidth = isDesktop ? screenWidth * 0.35 : screenWidth - 64;

    return (
      <>
        {/* Performance Overview */}
        <View
          className={`${styles.cardBg} p-6 mb-6 ${isDesktop ? "w-full" : ""}`}
        >
          <Text className="text-primary-800 font-poppins_600 text-lg mb-4 text-center">
            Performance Overview
          </Text>
          {chartType === "circular" ? (
            <View className="items-center">
              <CircularProgress
                value={performanceMetrics.averageCompletionRate}
                radius={isDesktop ? 100 : 80}
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
                  fontSize: isDesktop ? 18 : 16,
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
              width={chartWidth}
              height={isDesktop ? 300 : 220}
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
        <View
          className={`${styles.cardBg} p-6 mb-6 ${isDesktop ? "w-full" : ""}`}
        >
          <Text className="text-primary-800 font-poppins_600 text-lg mb-4 text-center">
            Task Distribution
          </Text>
          {performanceMetrics.totalTasks > 0 ? (
            <>
              <PieChart
                data={pieChartData}
                width={chartWidth}
                height={isDesktop ? 300 : 200}
                chartConfig={{
                  ...chartConfig,
                  color: (opacity = 1) => `rgba(126, 34, 206, ${opacity})`,
                }}
                accessor="population"
                backgroundColor="transparent"
                paddingLeft="15"
                absolute
                hasLegend={false}
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
        <View
          className={`${styles.cardBg} p-6 mb-6 ${isDesktop ? "w-full" : ""}`}
        >
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
      </>
    );
  };
  return (
    <View className="flex-1 bg-primary-50">
      {/* Mobile Layout */}
      <View className="lg:hidden flex-1">
        <ScrollView>
          {/* Mobile Header Section */}
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
            {/* Mobile Time Filter Buttons */}
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

            {/* Mobile Chart Type Toggle */}
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
                    <Ionicons
                      name={type === "circular" ? "pie-chart" : "stats-chart"}
                      size={18}
                      color={chartType === type ? "#ffffff" : "#7e22ce"}
                    />
                  </View>
                </TouchableOpacity>
              ))}
            </View>

            {/* Mobile Charts and Stats */}
            {renderCharts()}

            {/* Mobile Sign Out Button */}
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
      </View>

      {/* Desktop Layout */}
      <View className="hidden lg:flex flex-row min-h-screen">
        {/* Desktop Sidebar - Fixed */}
        <View className={`${desktopStyles.sidebar} fixed`}>
          <Text className="text-primary-50 font-poppins_700 text-2xl mb-4">
            Task Analytics
          </Text>
          <Text className="text-primary-200 font-poppins_400 mb-8">
            {user?.email}
          </Text>

          {/* Desktop Filter Controls */}
          <View className="space-y-4">
            <Text className="text-primary-100 font-poppins_600 mb-2">
              Time Range
            </Text>
            {(chartType === "circular"
              ? ["daily", "week", "month"]
              : ["week", "month"]
            ).map((filter) => (
              <TouchableOpacity
                key={filter}
                onPress={() =>
                  setTimeFilter(filter as "daily" | "week" | "month")
                }
                className={`px-4 py-3 rounded-xl ${
                  timeFilter === filter ? "bg-primary-600" : "bg-primary-700/30"
                }`}
              >
                <Text
                  className={`${
                    timeFilter === filter ? "text-white" : "text-primary-200"
                  } capitalize font-poppins_500`}
                >
                  {filter}
                </Text>
              </TouchableOpacity>
            ))}

            <Text className="text-primary-100 font-poppins_600 mb-2 mt-8">
              Chart Type
            </Text>
            {["circular", "line"].map((type) => (
              <TouchableOpacity
                key={type}
                onPress={() => {
                  if (timeFilter === "daily" && type === "line") {
                    setTimeFilter("week");
                  }
                  setChartType(type as "circular" | "line");
                }}
                className={`px-4 py-3 rounded-xl ${
                  chartType === type ? "bg-primary-600" : "bg-primary-700/30"
                }`}
              >
                <View className="flex-row items-center">
                  <Ionicons
                    name={type === "circular" ? "pie-chart" : "stats-chart"}
                    size={18}
                    color={chartType === type ? "#ffffff" : "#94a3b8"}
                  />
                  <Text
                    className={`${
                      chartType === type ? "text-white" : "text-primary-200"
                    } capitalize font-poppins_500 ml-2`}
                  >
                    {type}
                  </Text>
                </View>
              </TouchableOpacity>
            ))}
          </View>

          {/* Desktop Sign Out Button */}
          <TouchableOpacity
            onPress={signOut}
            className="bg-primary-600 p-4 rounded-xl mt-auto mb-6"
          >
            <Text className="text-white text-center font-poppins_600">
              Sign Out
            </Text>
          </TouchableOpacity>
        </View>

        {/* Desktop Main Content - Scrollable */}
        <View className="flex-1 ml-[300px]">
          {" "}
          {/* Width of sidebar */}
          <ScrollView className={`${desktopStyles.mainContent} h-screen`}>
            <View className="max-w-[1200px] mx-auto">
              <View className={desktopStyles.chartContainer}>
                {renderCharts(true)}
              </View>
            </View>
          </ScrollView>
        </View>
      </View>
    </View>
  );
}
