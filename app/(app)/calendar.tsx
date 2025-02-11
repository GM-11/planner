import { DateNavigator } from "@/components/DateNavigator";
import { Task } from "@/utils/interfaces";
import { useEffect, useRef, useState } from "react";
import {
  View,
  Text,
  TouchableOpacity,
  ScrollView,
  ActivityIndicator,
} from "react-native";
import { Calendar as RNCalendar } from "react-native-calendars";
import { format, startOfWeek, endOfWeek, eachDayOfInterval } from "date-fns";
import { useTaskContext } from "@/context/TaskContext";
import { Ionicons } from "@expo/vector-icons";

type ViewType = "daily" | "weekly" | "monthly";

const styles = {
  headerBg: "bg-primary-800 rounded-b-[30px]",
  cardBg: "bg-white rounded-xl shadow-sm",
  taskItem: "bg-primary-600 rounded-lg shadow-sm",
  timeLabel: "text-primary-400 font-poppins_400",
};

const calendarTheme = {
  backgroundColor: "transparent",
  calendarBackground: "transparent",
  textSectionTitleColor: "#475569",
  selectedDayBackgroundColor: "#7e22ce",
  selectedDayTextColor: "#ffffff",
  todayTextColor: "#7e22ce",
  dayTextColor: "#1e293b",
  textDisabledColor: "#94a3b8",
  dotColor: "#7e22ce",
  selectedDotColor: "#ffffff",
  arrowColor: "#7e22ce",
  monthTextColor: "#1e293b",
  textDayFontFamily: "Poppins_400Regular",
  textMonthFontFamily: "Poppins_600SemiBold",
  textDayHeaderFontFamily: "Poppins_500Medium",
};

export default function Calendar() {
  const [selectedDate, setSelectedDate] = useState(new Date());
  const [viewType, setViewType] = useState<ViewType>("daily");
  const [tasks, setTasks] = useState<Task[]>([]);
  const [isLocalLoading, setIsLocalLoading] = useState(false);

  const timeScrollRef = useRef<ScrollView>(null);
  const { loadTasks, updateTasks, isLoading } = useTaskContext();

  const HOURS = Array.from({ length: 24 }, (_, i) => i);

  useEffect(() => {
    if (viewType === "daily" || viewType === "weekly") {
      const scrollToCurrentTime = () => {
        const now = new Date();
        const hour = now.getHours();
        const scrollPosition = hour * 80; // 80 is the height of each time slot
        timeScrollRef.current?.scrollTo({ y: scrollPosition, animated: true });
      };

      setTimeout(scrollToCurrentTime, 100);
    }
  }, [viewType]);

  useEffect(() => {
    if (viewType === "weekly") {
      loadWeekTasks();
    } else {
      loadTasksForDate();
    }
  }, [selectedDate, viewType]);

  const loadTasksForDate = async () => {
    setIsLocalLoading(true);
    try {
      const formattedDate = format(selectedDate, "yyyy-MM-dd");
      const loadedTasks = await loadTasks(formattedDate);
      setTasks(loadedTasks);
    } catch (error) {
      console.error("Error loading tasks:", error);
    } finally {
      setIsLocalLoading(false);
    }
  };

  const loadWeekTasks = async () => {
    setIsLocalLoading(true);
    try {
      const start = startOfWeek(selectedDate);
      const end = endOfWeek(selectedDate);
      const dates = eachDayOfInterval({ start, end });

      const weekTasks = await Promise.all(
        dates.map((date) => loadTasks(format(date, "yyyy-MM-dd"))),
      );
      setTasks(weekTasks.flat());
    } catch (error) {
      console.error("Error loading week tasks:", error);
    } finally {
      setIsLocalLoading(false);
    }
  };

  // const _addTask = async () => {
  //   if (newTask.trim() === "") return;

  //   const newTaskItem: Task = {
  //     id: Date.now(),
  //     text: newTask,
  //     startTime: format(startTime, "HH:mm"),
  //     endTime: format(endTime, "HH:mm"),
  //     date: format(selectedDate, "yyyy-MM-dd"),
  //     completed: false,
  //     importance: 0,
  //   };

  //   try {
  //     const updatedTasks = [...tasks, newTaskItem];
  //     await updateTasks(updatedTasks, newTaskItem.date);
  //     setTasks(updatedTasks);
  //     setShowNewTaskModal(false);
  //     resetForm();
  //   } catch (error) {
  //     console.error("Error adding task:", error);
  //   }
  // };

  const getTimeSlotTasks = (hour: number, date: Date) => {
    return tasks.filter((task) => {
      const taskDate = format(new Date(task.date), "yyyy-MM-dd");
      const currentDate = format(date, "yyyy-MM-dd");
      const taskStartHour = parseInt(task.startTime.split(":")[0]);
      return taskDate === currentDate && taskStartHour === hour;
    });
  };

  const CurrentTimeLine = () => {
    const [, forceUpdate] = useState({});

    useEffect(() => {
      // Update position every minute
      const interval = setInterval(() => forceUpdate({}), 60000);
      return () => clearInterval(interval);
    }, []);

    const now = new Date();
    const hours = now.getHours();
    const minutes = now.getMinutes();
    const timeInMinutes = hours * 60 + minutes;
    const oneMinuteHeight = 80 / 60;
    const topPosition = timeInMinutes * oneMinuteHeight;

    return (
      <View
        className="absolute left-16 right-0 h-0.5 bg-red-500 z-10"
        style={{
          top: topPosition,
        }}
      >
        <View className="absolute -left-1 -top-1.5 w-3 h-3 rounded-full bg-red-500" />
      </View>
    );
  };

  const ViewSelector = () => (
    <View className={`${styles.headerBg} px-6 py-4`}>
      <View className="flex-row items-center justify-between">
        <View className="flex-row items-center space-x-2">
          <Text className="text-primary-50 font-poppins_600 text-xl">
            {selectedDate.toLocaleString("default", {
              month: "long",
              year: "numeric",
            })}
          </Text>
          <Ionicons name="chevron-down" size={20} color="#f8fafc" />
        </View>
        <View className="flex-row space-x-2">
          {["daily", "weekly", "monthly"].map((view) => (
            <TouchableOpacity
              key={view}
              onPress={() => setViewType(view as ViewType)}
              className={`px-4 py-2 rounded-full ${
                viewType === view ? "bg-primary-600" : "bg-primary-700/30"
              }`}
            >
              <Text
                className={`font-poppins_500 text-sm text-primary-50 capitalize`}
              >
                {view}
              </Text>
            </TouchableOpacity>
          ))}
        </View>
      </View>
    </View>
  );

  const TaskList = () => (
    <ScrollView className="p-4">
      {tasks.length === 0 ? (
        <View className="flex-1 items-center justify-center py-12">
          <Text className="text-primary-400 font-poppins_500">
            No tasks for this day
          </Text>
        </View>
      ) : (
        tasks.map((task) => (
          <View
            key={task.id}
            className={`${styles.cardBg} p-4 mb-2 border-l-4`}
            style={{
              borderLeftColor: task.completed ? "#94a3b8" : "#7e22ce",
            }}
          >
            <Text className="font-poppins_600 text-primary-800">
              {task.text}
            </Text>
            <Text className="font-poppins_400 text-primary-400 text-sm">
              {task.startTime} - {task.endTime}
            </Text>
          </View>
        ))
      )}
    </ScrollView>
  );

  const TimeSlot = ({ hour, date }: { hour: number; date: Date }) => {
    const slotTasks = getTimeSlotTasks(hour, date);

    return (
      <View className="flex-row h-[80px] border-t border-primary-100">
        <View className="w-16 py-2">
          <Text className="text-primary-400 font-poppins_400 text-right pr-2">
            {hour === 0
              ? "12 AM"
              : hour < 12
                ? `${hour} AM`
                : hour === 12
                  ? "12 PM"
                  : `${hour - 12} PM`}
          </Text>
        </View>
        <View className="flex-1 border-l border-primary-200">
          {slotTasks.map((task) => (
            <View
              key={task.id}
              className="absolute rounded-lg p-2 left-0 right-0"
              style={{
                backgroundColor: `${task.completed ? "#94a3b8" : "#7e22ce"}`,
                top: `${(parseInt(task.startTime.split(":")[1]) / 60) * 100}%`,
                height: `${
                  ((parseInt(task.endTime.split(":")[0]) * 60 +
                    parseInt(task.endTime.split(":")[1]) -
                    (parseInt(task.startTime.split(":")[0]) * 60 +
                      parseInt(task.startTime.split(":")[1]))) /
                    60) *
                  100
                }%`,
              }}
            >
              <Text className="text-white font-poppins_500">{task.text}</Text>
              <Text className="text-primary-100 font-poppins_400 text-xs">
                {task.startTime} - {task.endTime}
              </Text>
            </View>
          ))}
        </View>
      </View>
    );
  };

  const WeekDayHeader = ({ date }: { date: Date }) => (
    <View className="flex-1 items-center p-2">
      <Text className="text-gray-500">{format(date, "EEE")}</Text>
      <TouchableOpacity onPress={() => setSelectedDate(date)}>
        <Text
          className={`text-sm ${
            format(date, "yyyy-MM-dd") === format(new Date(), "yyyy-MM-dd")
              ? "text-blue-600 font-bold"
              : ""
          }`}
        >
          {format(date, "d")}
        </Text>
      </TouchableOpacity>
    </View>
  );

  const renderDailyView = () => (
    <View className="flex-1">
      <DateNavigator
        selectedDate={selectedDate}
        onDateChange={setSelectedDate}
        variant="light"
      />
      {isLocalLoading || isLoading ? (
        <LoadingIndicator />
      ) : (
        <ScrollView ref={timeScrollRef}>
          {format(selectedDate, "yyyy-MM-dd") ===
            format(new Date(), "yyyy-MM-dd") && <CurrentTimeLine />}
          {HOURS.map((hour) => (
            <TimeSlot key={hour} hour={hour} date={selectedDate} />
          ))}
        </ScrollView>
      )}
    </View>
  );

  const renderWeeklyView = () => {
    const weekDates = eachDayOfInterval({
      start: startOfWeek(selectedDate),
      end: endOfWeek(selectedDate),
    });

    return (
      <View className="flex-1">
        <View className="flex-row border-b border-gray-200">
          <View className="w-16" />
          {weekDates.map((date) => (
            <WeekDayHeader key={date.toISOString()} date={date} />
          ))}
        </View>
        {isLocalLoading || isLoading ? (
          <LoadingIndicator />
        ) : (
          <ScrollView ref={timeScrollRef}>
            {weekDates.some(
              (date) =>
                format(date, "yyyy-MM-dd") === format(new Date(), "yyyy-MM-dd"),
            ) && <CurrentTimeLine />}
            {HOURS.map((hour) => (
              <View
                key={hour}
                className="flex-row h-[80px] border-t border-gray-100"
              >
                <View className="w-16 py-2">
                  <Text className="text-gray-500 text-right pr-2">
                    {hour === 0
                      ? "12 AM"
                      : hour < 12
                        ? `${hour} AM`
                        : hour === 12
                          ? "12 PM"
                          : `${hour - 12} PM`}
                  </Text>
                </View>
                {weekDates.map((date) => (
                  <View
                    key={date.toISOString()}
                    className="flex-1 border-l border-gray-200"
                  >
                    {getTimeSlotTasks(hour, date).map((task) => (
                      <View
                        key={task.id}
                        className="absolute m-1 rounded-lg p-2 left-0 right-0"
                        style={{
                          backgroundColor: `${task.completed ? "#94a3b8" : "#7e22ce"}`, // Using theme colors
                          top: `${(parseInt(task.startTime.split(":")[1]) / 60) * 100}%`,
                          height: `${
                            ((parseInt(task.endTime.split(":")[0]) * 60 +
                              parseInt(task.endTime.split(":")[1]) -
                              (parseInt(task.startTime.split(":")[0]) * 60 +
                                parseInt(task.startTime.split(":")[1]))) /
                              60) *
                            100
                          }%`,
                          opacity: task.completed ? 0.6 : 1, // Adding opacity for completed tasks
                        }}
                      >
                        {/* Only show text if the task duration is long enough */}
                        {parseInt(task.endTime.split(":")[0]) * 60 +
                          parseInt(task.endTime.split(":")[1]) -
                          (parseInt(task.startTime.split(":")[0]) * 60 +
                            parseInt(task.startTime.split(":")[1])) >=
                        30 ? (
                          <>
                            <Text className="text-white font-poppins_500 text-xs line-clamp-1">
                              {task.text}
                            </Text>
                            <Text className="text-primary-100 font-poppins_400 text-xs">
                              {task.startTime} - {task.endTime}
                            </Text>
                          </>
                        ) : (
                          <Text className="text-white font-poppins_500 text-xs line-clamp-1">
                            {task.text}
                          </Text>
                        )}
                      </View>
                    ))}
                  </View>
                ))}
              </View>
            ))}
          </ScrollView>
        )}
      </View>
    );
  };

  const renderMonthlyView = () => (
    <View className="flex-1">
      {/* Use flexRow only for web view */}
      <View className="flex-1 md:flex-row">
        {/* Tasks Section - Hidden on mobile, shown on left for web */}
        <View className="hidden md:flex md:w-1/3 md:border-r md:border-gray-200">
          {isLocalLoading || isLoading ? (
            <LoadingIndicator />
          ) : (
            <ScrollView className="p-4">
              <Text className="text-lg font-semibold mb-4">
                Tasks for {format(selectedDate, "MMMM d, yyyy")}
              </Text>
              <TaskList />
            </ScrollView>
          )}
        </View>

        {/* Calendar Section */}
        <View className="flex-1">
          <RNCalendar
            onDayPress={(day: any) => {
              setSelectedDate(new Date(day.timestamp));
            }}
            markedDates={{
              [format(selectedDate, "yyyy-MM-dd")]: { selected: true },
            }}
          />

          {/* Mobile Tasks Section - Hidden on web */}
          <View className="md:hidden flex-1">
            {isLocalLoading || isLoading ? <LoadingIndicator /> : <TaskList />}
          </View>
        </View>
      </View>
    </View>
  );

  const LoadingIndicator = () => (
    <View className="flex-1 justify-center items-center">
      <ActivityIndicator size="large" color="#4285f4" />
    </View>
  );

  return (
    <View className="flex-1 bg-primary-50">
      <ViewSelector />

      <View className="flex-1">
        {viewType === "daily" && renderDailyView()}
        {viewType === "weekly" && renderWeeklyView()}
        {viewType === "monthly" && renderMonthlyView()}
      </View>
    </View>
  );
}
