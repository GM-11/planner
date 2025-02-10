import React, { useEffect, useState } from "react";
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  ScrollView,
  Modal,
  Platform,
} from "react-native";
import * as Notifications from "expo-notifications";
import { Ionicons } from "@expo/vector-icons";
import { Task } from "@/utils/interfaces";
import Slider from "@react-native-community/slider";
import DateTimePicker, {
  DateTimePickerEvent,
} from "@react-native-community/datetimepicker";
import { format } from "date-fns";
import { DateNavigator } from "@/components/DateNavigator";
import { useTaskContext } from "@/context/TaskContext";
import { importanceColors, importanceLevels } from "@/utils/constants";
import { LoadingIndicator } from "@/components/LoadingIndicator";

type SortType = "time" | "importance";
type SortDirection = "asc" | "desc";

const styles = {
  headerBg: "bg-primary-800 rounded-b-[30px]",
  cardBg: "bg-white rounded-xl shadow-sm",
  inputContainer:
    "bg-white rounded-2xl px-4 shadow-sm border border-primary-200",
  modalBg: "bg-primary-50",
};

const desktopStyles = {
  container: "lg:flex-row lg:max-w-7xl lg:mx-auto lg:h-screen",
  sidebar: "lg:w-1/4 lg:min-w-[300px] lg:bg-primary-800 lg:h-screen lg:pt-6",
  mainContent: "lg:w-3/4 lg:px-8 lg:py-6",
};

const TimeInput = ({
  value,
  onChange,
  label,
  setShowStartPicker,
  setShowEndPicker,
}: {
  value: Date;
  onChange: (date: Date) => void;
  label: string;
  setShowStartPicker?: (show: boolean) => void;
  setShowEndPicker?: (show: boolean) => void;
}) => {
  // Format time for display and input
  const timeString = format(value, "HH:mm");
  const [inputValue, setInputValue] = useState(timeString);

  // Update input value when the date prop changes
  useEffect(() => {
    setInputValue(format(value, "HH:mm"));
  }, [value]);

  if (Platform.OS === "web") {
    return (
      <View className="mb-4">
        <Text className="text-sm text-gray-600 mb-2">{label}</Text>
        <input
          type="time"
          className="border border-gray-300 p-3 rounded-lg w-full"
          value={inputValue}
          onChange={(e) => {
            const newValue = e.target.value;
            setInputValue(newValue);

            if (newValue) {
              const [hours, minutes] = newValue.split(":");
              const newDate = new Date(value);
              newDate.setHours(parseInt(hours, 10));
              newDate.setMinutes(parseInt(minutes, 10));
              onChange(newDate);
            }
          }}
          style={{
            height: 48,
            fontSize: 16,
            outline: "none",
            cursor: "pointer",
          }}
        />
      </View>
    );
  }

  return (
    <View className="mb-4">
      <Text className="text-sm text-gray-600 mb-2">{label}</Text>
      <TouchableOpacity
        className="border border-gray-300 p-3 rounded-lg"
        onPress={() => {
          if (label === "Start Time" && setShowStartPicker) {
            setShowStartPicker(true);
          } else if (label === "End Time" && setShowEndPicker) {
            setShowEndPicker(true);
          }
        }}
      >
        <Text>{timeString}</Text>
      </TouchableOpacity>
    </View>
  );
};

export default function Tasks() {
  const { loadTasks, updateTasks, isLoading } = useTaskContext();
  const [tasks, setTasks] = useState<Task[]>([]);
  const [isModalVisible, setIsModalVisible] = useState(false);
  const [selectedDate, setSelectedDate] = useState(new Date());
  const [newTask, setNewTask] = useState<string>("");
  const [startTime, setStartTime] = useState<Date>(new Date());
  const [endTime, setEndTime] = useState<Date>(new Date());
  const [showStartPicker, setShowStartPicker] = useState(false);
  const [showEndPicker, setShowEndPicker] = useState(false);
  const [isLocalLoading, setIsLocalLoading] = useState(false);
  const [importance, setImportance] = useState<number>(0);
  const [sortType, setSortType] = useState<SortType>("time");
  const [sortDirection, setSortDirection] = useState<SortDirection>("asc");

  useEffect(() => {
    loadTasksForDate();
  }, [selectedDate]);

  const getSortedTasks = (tasks: Task[]) => {
    const filteredTasks = tasks.filter(
      (task) => task.date === format(selectedDate, "yyyy-MM-dd"),
    );

    return filteredTasks.sort((a, b) => {
      if (sortType === "time") {
        const comparison = a.startTime.localeCompare(b.startTime);
        return sortDirection === "asc" ? comparison : -comparison;
      } else {
        const comparison = b.importance - a.importance;
        return sortDirection === "asc" ? -comparison : comparison;
      }
    });
  };

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

  const addTask = async (): Promise<void> => {
    if (newTask.trim() === "") return;

    const newTaskItem: Task = {
      id: Date.now(),
      text: newTask,
      startTime: format(startTime, "HH:mm"),
      endTime: format(endTime, "HH:mm"),
      date: format(selectedDate, "yyyy-MM-dd"),
      completed: false,
      importance,
    };

    try {
      const updatedTasks = [...tasks, newTaskItem];
      await updateTasks(updatedTasks, newTaskItem.date);
      setTasks(updatedTasks);
      setIsModalVisible(false);
      resetForm();
      Notifications.scheduleNotificationAsync({
        content: {
          title: "Task Reminder",
          body: `Time for ${newTask}`,
        },
        trigger: {
          type: Notifications.SchedulableTriggerInputTypes.DATE,
          date: new Date(startTime),
        },
      });
    } catch (error) {
      console.error("Error adding task:", error);
    }
  };

  const toggleTask = async (taskId: number): Promise<void> => {
    try {
      const updatedTasks = tasks.map((task) =>
        task.id === taskId ? { ...task, completed: !task.completed } : task,
      );
      await updateTasks(updatedTasks, format(selectedDate, "yyyy-MM-dd"));
      setTasks(updatedTasks);
    } catch (error) {
      console.error("Error toggling task:", error);
    }
  };

  const deleteTask = async (taskId: number): Promise<void> => {
    try {
      const updatedTasks = tasks.filter((task) => task.id !== taskId);
      await updateTasks(updatedTasks, format(selectedDate, "yyyy-MM-dd"));
      setTasks(updatedTasks);
    } catch (error) {
      console.error("Error deleting task:", error);
    }
  };

  const resetForm = () => {
    setNewTask("");
    setStartTime(new Date());
    setEndTime(new Date());
    setShowStartPicker(false);
    setShowEndPicker(false);
    setImportance(0); // Reset importance
  };

  const filteredTasks = tasks.filter(
    (task) => task.date === format(selectedDate, "yyyy-MM-dd"),
  );
  const onTimeChange = (
    event: DateTimePickerEvent,
    selectedTime: Date | undefined,
    type: "start" | "end",
  ) => {
    if (Platform.OS === "android") {
      setShowStartPicker(false);
      setShowEndPicker(false);
    }

    if (selectedTime) {
      if (type === "start") {
        setStartTime(selectedTime);
      } else {
        setEndTime(selectedTime);
      }
    }
  };
  return (
    <View className="flex-1 bg-primary-50">
      {/* Mobile Layout */}
      <View className="lg:hidden flex-1">
        {/* Mobile Header Section */}
        <View className={styles.headerBg}>
          <DateNavigator
            selectedDate={selectedDate}
            onDateChange={setSelectedDate}
          />

          {/* Mobile Sort Controls */}
          <View className="flex-row justify-between items-center px-6 pb-6">
            <Text className="text-primary-100 font-poppins_600 text-lg">
              Your Tasks
            </Text>
            <View className="flex-row items-center space-x-2">
              <TouchableOpacity
                className={`px-4 py-2 rounded-full ${
                  sortType === "time" ? "bg-primary-600" : "bg-primary-700/30"
                }`}
                onPress={() => setSortType("time")}
              >
                <Text className="text-primary-50 font-poppins_500 text-sm">
                  Time
                </Text>
              </TouchableOpacity>
              <TouchableOpacity
                className={`px-4 py-2 rounded-full ${
                  sortType === "importance"
                    ? "bg-primary-600"
                    : "bg-primary-700/30"
                }`}
                onPress={() => setSortType("importance")}
              >
                <Text className="text-primary-50 font-poppins_500 text-sm">
                  Priority
                </Text>
              </TouchableOpacity>
              <TouchableOpacity
                onPress={() =>
                  setSortDirection((prev) => (prev === "asc" ? "desc" : "asc"))
                }
                className="w-8 h-8 rounded-full bg-primary-700/30 items-center justify-center"
              >
                <Ionicons
                  name={sortDirection === "asc" ? "arrow-up" : "arrow-down"}
                  size={18}
                  color="#f1f5f9"
                />
              </TouchableOpacity>
            </View>
          </View>
        </View>

        {/* Mobile Tasks List */}
        {isLocalLoading || isLoading ? (
          <LoadingIndicator />
        ) : (
          <ScrollView className="flex-1 px-4 pt-4">
            {getSortedTasks(filteredTasks).length === 0 ? (
              <View className="flex-1 items-center justify-center py-12">
                <Ionicons name="calendar-outline" size={48} color="#94a3b8" />
                <Text className="text-primary-400 font-poppins_500 mt-4">
                  No tasks for this day
                </Text>
              </View>
            ) : (
              getSortedTasks(filteredTasks).map((task: Task) => (
                <View
                  key={task.id}
                  className={`mb-3 ${styles.cardBg} border-l-4 ${
                    task.completed ? "opacity-60" : ""
                  }`}
                  style={{ borderLeftColor: importanceColors[task.importance] }}
                >
                  <View className="flex-row items-center p-4">
                    <TouchableOpacity
                      onPress={() => toggleTask(task.id)}
                      className="flex-row items-center flex-1"
                    >
                      <View
                        className={`w-6 h-6 rounded-full border-2 mr-3 items-center justify-center ${
                          task.completed
                            ? "bg-primary-600 border-primary-600"
                            : "border-primary-300"
                        }`}
                      >
                        {task.completed && (
                          <Ionicons name="checkmark" size={16} color="white" />
                        )}
                      </View>
                      <View>
                        <Text
                          className={`font-poppins_600 text-primary-800 ${
                            task.completed ? "line-through" : ""
                          }`}
                        >
                          {task.text}
                        </Text>
                        <Text className="font-poppins_400 text-primary-400 text-sm">
                          {task.startTime} - {task.endTime}
                        </Text>
                      </View>
                    </TouchableOpacity>
                    <TouchableOpacity
                      onPress={() => deleteTask(task.id)}
                      className="p-2"
                    >
                      <Ionicons
                        name="trash-outline"
                        size={20}
                        color="#ef4444"
                      />
                    </TouchableOpacity>
                  </View>
                </View>
              ))
            )}
          </ScrollView>
        )}

        {/* Mobile Add Task Button */}
        <TouchableOpacity
          onPress={() => setIsModalVisible(true)}
          disabled={isLocalLoading}
          className="absolute bottom-6 right-6 w-14 h-14 bg-primary-600
                       rounded-full items-center justify-center shadow-lg"
        >
          <Ionicons name="add" size={30} color="white" />
        </TouchableOpacity>
      </View>
      {/* Desktop Layout */}
      <View className="hidden lg:flex flex-1 flex-row">
        {/* Left Sidebar */}
        <View className={desktopStyles.sidebar}>
          <View className="px-6">
            <Text className="text-primary-50 font-poppins_700 text-2xl mb-8">
              Task Planner
            </Text>
            <DateNavigator
              selectedDate={selectedDate}
              onDateChange={setSelectedDate}
            />

            {/* Desktop Sort Controls */}
            <View className="mt-8 space-y-4">
              <Text className="text-primary-100 font-poppins_600">Sort By</Text>
              <View className="space-y-2">
                <TouchableOpacity
                  className={`px-4 py-3 rounded-xl ${
                    sortType === "time" ? "bg-primary-600" : "bg-primary-700/30"
                  }`}
                  onPress={() => setSortType("time")}
                >
                  <Text className="text-primary-50 font-poppins_500">Time</Text>
                </TouchableOpacity>
                <TouchableOpacity
                  className={`px-4 py-3 rounded-xl ${
                    sortType === "importance"
                      ? "bg-primary-600"
                      : "bg-primary-700/30"
                  }`}
                  onPress={() => setSortType("importance")}
                >
                  <Text className="text-primary-50 font-poppins_500">
                    Priority
                  </Text>
                </TouchableOpacity>
                <TouchableOpacity
                  onPress={() =>
                    setSortDirection((prev) =>
                      prev === "asc" ? "desc" : "asc",
                    )
                  }
                  className="px-4 py-3 rounded-xl bg-primary-700/30 flex-row items-center"
                >
                  <Text className="text-primary-50 font-poppins_500 mr-2">
                    Order
                  </Text>
                  <Ionicons
                    name={sortDirection === "asc" ? "arrow-up" : "arrow-down"}
                    size={18}
                    color="#f1f5f9"
                  />
                </TouchableOpacity>
              </View>
            </View>
          </View>
        </View>

        {/* Main Content Area */}
        <View className={desktopStyles.mainContent}>
          {/* Desktop Header */}
          <View className="flex-row justify-between items-center mb-6">
            <Text className="text-primary-800 font-poppins_700 text-2xl">
              Your Tasks
            </Text>
            <TouchableOpacity
              onPress={() => setIsModalVisible(true)}
              className="bg-primary-600 px-6 py-3 rounded-xl flex-row items-center"
            >
              <Ionicons name="add" size={24} color="white" />
              <Text className="text-white font-poppins_600 ml-2">
                Add New Task
              </Text>
            </TouchableOpacity>
          </View>

          {/* Desktop Tasks List */}
          {isLocalLoading || isLoading ? (
            <LoadingIndicator />
          ) : (
            <ScrollView className="flex-1">
              {getSortedTasks(filteredTasks).length === 0 ? (
                <View className="flex-1 items-center justify-center py-12">
                  <Ionicons name="calendar-outline" size={64} color="#94a3b8" />
                  <Text className="text-primary-400 font-poppins_500 mt-4">
                    No tasks for this day
                  </Text>
                </View>
              ) : (
                getSortedTasks(filteredTasks).map((task: Task) => (
                  <View
                    key={task.id}
                    className={`mb-3 ${styles.cardBg} border-l-4 ${
                      task.completed ? "opacity-60" : ""
                    }`}
                    style={{
                      borderLeftColor: importanceColors[task.importance],
                    }}
                  >
                    <View className="flex-row items-center p-4">
                      <TouchableOpacity
                        onPress={() => toggleTask(task.id)}
                        className="flex-row items-center flex-1"
                      >
                        <View
                          className={`w-6 h-6 rounded-full border-2 mr-3 items-center justify-center ${
                            task.completed
                              ? "bg-primary-600 border-primary-600"
                              : "border-primary-300"
                          }`}
                        >
                          {task.completed && (
                            <Ionicons
                              name="checkmark"
                              size={16}
                              color="white"
                            />
                          )}
                        </View>
                        <View>
                          <Text
                            className={`font-poppins_600 text-primary-800 ${
                              task.completed ? "line-through" : ""
                            }`}
                          >
                            {task.text}
                          </Text>
                          <Text className="font-poppins_400 text-primary-400 text-sm">
                            {task.startTime} - {task.endTime}
                          </Text>
                        </View>
                      </TouchableOpacity>
                      <TouchableOpacity
                        onPress={() => deleteTask(task.id)}
                        className="p-2"
                      >
                        <Ionicons
                          name="trash-outline"
                          size={20}
                          color="#ef4444"
                        />
                      </TouchableOpacity>
                    </View>
                  </View>
                ))
              )}
            </ScrollView>
          )}
        </View>
      </View>

      {/* Add Task Modal */}
      <Modal
        animationType="slide"
        transparent={true}
        visible={isModalVisible}
        onRequestClose={() => {
          setIsModalVisible(false);
          resetForm();
        }}
      >
        <View className="flex-1 justify-end bg-black/30">
          <View
            className={`${styles.modalBg} rounded-t-3xl p-6 lg:max-w-lg lg:mx-auto lg:my-auto lg:rounded-3xl`}
          >
            <View className="flex-row justify-between items-center mb-6">
              <Text className="text-xl font-poppins_600 text-primary-800">
                Add New Task
              </Text>
              <TouchableOpacity
                onPress={() => {
                  setIsModalVisible(false);
                  resetForm();
                }}
                className="p-2"
              >
                <Ionicons name="close" size={24} color="#475569" />
              </TouchableOpacity>
            </View>

            {/* Task Input */}
            <View className="mb-6">
              <Text className="text-primary-700 font-poppins_500 mb-2 ml-1">
                Task Name
              </Text>
              <View className={styles.inputContainer}>
                <TextInput
                  value={newTask}
                  onChangeText={setNewTask}
                  placeholder="Enter task name"
                  className="p-4 font-poppins_400 text-primary-800"
                  placeholderTextColor="#94a3b8"
                />
              </View>
            </View>

            {/* Time Inputs */}
            <View className="flex-row space-x-4 mb-6">
              <View className="flex-1">
                <Text className="text-primary-700 font-poppins_500 mb-2 ml-1">
                  Start Time
                </Text>
                <View className={styles.inputContainer}>
                  <TimeInput
                    value={startTime}
                    onChange={(date) => {
                      setStartTime(date);
                      setShowStartPicker(false);
                    }}
                    label="Start Time"
                    setShowStartPicker={setShowStartPicker}
                    setShowEndPicker={setShowEndPicker}
                  />
                </View>
              </View>
              <View className="flex-1">
                <Text className="text-primary-700 font-poppins_500 mb-2 ml-1">
                  End Time
                </Text>
                <View className={styles.inputContainer}>
                  <TimeInput
                    value={endTime}
                    onChange={(date) => {
                      setEndTime(date);
                      setShowEndPicker(false);
                    }}
                    label="End Time"
                    setShowStartPicker={setShowStartPicker}
                    setShowEndPicker={setShowEndPicker}
                  />
                </View>
              </View>
            </View>

            {/* Importance Slider */}
            <View className="mb-6">
              <Text className="text-primary-700 font-poppins_500 mb-4">
                Priority Level
              </Text>
              <Slider
                minimumValue={0}
                maximumValue={3}
                step={1}
                value={importance}
                onValueChange={setImportance}
                minimumTrackTintColor={importanceColors[importance]}
                maximumTrackTintColor="#e2e8f0"
                thumbTintColor={importanceColors[importance]}
              />
              <Text
                className="text-center font-poppins_500 mt-2"
                style={{ color: importanceColors[importance] }}
              >
                {importanceLevels[importance]}
              </Text>
            </View>

            {/* Add Button */}
            <TouchableOpacity
              onPress={addTask}
              className="bg-primary-600 p-4 rounded-xl"
            >
              <Text className="text-white text-center font-poppins_600">
                Add Task
              </Text>
            </TouchableOpacity>
          </View>
        </View>
      </Modal>

      {/* Time Picker (Platform Specific) */}
      {Platform.OS !== "web" && (
        <>
          {Platform.OS === "android" ? (
            (showStartPicker || showEndPicker) && (
              <DateTimePicker
                value={showStartPicker ? startTime : endTime}
                mode="time"
                is24Hour={true}
                onChange={(event, date) =>
                  onTimeChange(event, date, showStartPicker ? "start" : "end")
                }
              />
            )
          ) : (
            <>
              {showStartPicker && (
                <DateTimePicker
                  value={startTime}
                  mode="time"
                  is24Hour={true}
                  onChange={(event, date) => onTimeChange(event, date, "start")}
                  style={{ width: 100 }}
                />
              )}
              {showEndPicker && (
                <DateTimePicker
                  value={endTime}
                  mode="time"
                  is24Hour={true}
                  onChange={(event, date) => onTimeChange(event, date, "end")}
                  style={{ width: 100 }}
                />
              )}
            </>
          )}
        </>
      )}
    </View>
  );
}
