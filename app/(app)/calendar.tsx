import { DateNavigator } from "@/components/DateNavigator";
import { Task } from "@/utils/interfaces";
import { useEffect, useRef, useState } from "react";
import {
  View,
  Text,
  TouchableOpacity,
  ScrollView,
  Modal,
  TextInput,
  ActivityIndicator,
  Keyboard,
  Platform,
  KeyboardAvoidingView,
  Pressable,
  TouchableWithoutFeedback,
  PixelRatio,
} from "react-native";
import { Calendar as RNCalendar } from "react-native-calendars";
import { Plus, ChevronDown } from "lucide-react-native";
import { format, startOfWeek, endOfWeek, eachDayOfInterval } from "date-fns";
import DateTimePicker, {
  DateTimePickerEvent,
} from "@react-native-community/datetimepicker";
import { useTaskContext } from "@/context/TaskContext";

type ViewType = "daily" | "weekly" | "monthly";

export default function Calendar() {
  const [selectedDate, setSelectedDate] = useState(new Date());
  const [viewType, setViewType] = useState<ViewType>("daily");
  const [tasks, setTasks] = useState<Task[]>([]);
  const [, setShowNewTaskModal] = useState(false);
  const [newTask, setNewTask] = useState("");
  const [startTime, setStartTime] = useState(new Date());
  const [endTime, setEndTime] = useState(new Date());
  const [, setShowStartPicker] = useState(false);
  const [, setShowEndPicker] = useState(false);
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

  const _addTask = async () => {
    if (newTask.trim() === "") return;

    const newTaskItem: Task = {
      id: Date.now(),
      text: newTask,
      startTime: format(startTime, "HH:mm"),
      endTime: format(endTime, "HH:mm"),
      date: format(selectedDate, "yyyy-MM-dd"),
      completed: false,
      importance: "mildly-important",
    };

    try {
      const updatedTasks = [...tasks, newTaskItem];
      await updateTasks(updatedTasks, newTaskItem.date);
      setTasks(updatedTasks);
      setShowNewTaskModal(false);
      resetForm();
    } catch (error) {
      console.error("Error adding task:", error);
    }
  };

  const getTimeSlotTasks = (hour: number, date: Date) => {
    return tasks.filter((task) => {
      const taskDate = format(new Date(task.date), "yyyy-MM-dd");
      const currentDate = format(date, "yyyy-MM-dd");
      const taskStartHour = parseInt(task.startTime.split(":")[0]);
      return taskDate === currentDate && taskStartHour === hour;
    });
  };

  const resetForm = () => {
    setNewTask("");
    setStartTime(new Date());
    setEndTime(new Date());
    setShowStartPicker(false);
    setShowEndPicker(false);
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
    <View className="flex-row items-center px-4 py-2 border-b border-gray-200">
      <View className="flex-row items-center flex-1">
        <Text className="text-xl font-semibold">
          {selectedDate.toLocaleString("default", {
            month: "long",
            year: "numeric",
          })}
        </Text>
        <ChevronDown size={20} className="ml-1" />
      </View>
      <View className="flex-row space-x-2">
        {["daily", "weekly", "monthly"].map((view) => (
          <TouchableOpacity
            key={view}
            onPress={() => setViewType(view as ViewType)}
            className={`px-3 py-1 rounded-md ${
              viewType === view ? "bg-blue-100" : ""
            }`}
          >
            <Text
              className={`${
                viewType === view ? "text-blue-600" : "text-gray-600"
              } capitalize`}
            >
              {view}
            </Text>
          </TouchableOpacity>
        ))}
      </View>
    </View>
  );

  const TaskList = () => (
    <ScrollView className="p-4">
      {tasks.length === 0 ? (
        <Text className="text-gray-500 text-center">No tasks for this day</Text>
      ) : (
        tasks.map((task) => (
          <View
            key={task.id}
            className="p-4 mb-2 bg-white rounded-lg border border-gray-200"
          >
            <Text className="font-semibold">{task.text}</Text>
            <Text className="text-gray-500 text-sm">
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
      <View className="flex-row h-[80px] border-t border-gray-100">
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
        <View className="flex-1 border-l border-gray-200">
          {slotTasks.map((task) => (
            <View
              key={task.id}
              className="absolute m-1 rounded p-2 left-0 right-0 bg-blue-500"
              style={{
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
              <Text className="text-white font-medium">{task.text}</Text>
              <Text className="text-white text-xs">
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
                        className="absolute m-1 rounded p-2 left-0 right-0 bg-blue-500"
                        style={{
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
                        <Text className="text-white font-medium text-xs">
                          {task.text}
                        </Text>
                        <Text className="text-white text-xs">
                          {task.startTime} - {task.endTime}
                        </Text>
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
            onDayPress={(day) => {
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
    <View className="flex-1 bg-white">
      <ViewSelector />

      {viewType === "daily" && renderDailyView()}
      {viewType === "weekly" && renderWeeklyView()}
      {viewType === "monthly" && renderMonthlyView()}

      {/* <TouchableOpacity
        onPress={() => setShowNewTaskModal(true)}
        className="absolute bottom-6 right-6 w-14 h-14 bg-blue-600 rounded-full items-center justify-center shadow-lg"
      >
        <Plus color="white" size={24} />
      </TouchableOpacity> */}

      {/* <NewTaskModal /> */}
    </View>
  );
}
