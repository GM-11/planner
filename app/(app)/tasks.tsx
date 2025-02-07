import React, { useEffect, useState } from "react";
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  ScrollView,
  Modal,
  Platform,
  ActivityIndicator,
} from "react-native";
import { Ionicons } from "@expo/vector-icons";
import { Task } from "@/utils/interfaces";
import Slider from "@react-native-community/slider";
import DateTimePicker, {
  DateTimePickerEvent,
} from "@react-native-community/datetimepicker";
import { format } from "date-fns";
import { DateNavigator } from "@/components/DateNavigator";
import { useTaskContext } from "@/context/TaskContext";

type SortType = "time" | "importance";
type SortDirection = "asc" | "desc";

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
  const [importance, setImportance] = useState<Task["importance"]>("important");
  const [sortType, setSortType] = useState<SortType>("time");
  const [sortDirection, setSortDirection] = useState<SortDirection>("asc");

  useEffect(() => {
    loadTasksForDate();
  }, [selectedDate]);

  const getImportanceLevel = (value: number): Task["importance"] => {
    if (value <= 0.25) return "less-important";
    if (value <= 0.5) return "mildly-important";
    if (value <= 0.75) return "important";
    return "very-important";
  };

  const getImportanceColor = (importance: Task["importance"]): string => {
    switch (importance) {
      case "very-important":
        return "#ef4444";
      case "important":
        return "#f97316";
      case "mildly-important":
        return "#eab308";
      case "less-important":
        return "#22c55e";
      default:
        return "#gray-500";
    }
  };

  const getSortedTasks = (tasks: Task[]) => {
    const filteredTasks = tasks.filter(
      (task) => task.date === format(selectedDate, "yyyy-MM-dd"),
    );

    return filteredTasks.sort((a, b) => {
      if (sortType === "time") {
        const comparison = a.startTime.localeCompare(b.startTime);
        return sortDirection === "asc" ? comparison : -comparison;
      } else {
        const importanceOrder = {
          "very-important": 4,
          important: 3,
          "mildly-important": 2,
          "less-important": 1,
        };
        const comparison =
          importanceOrder[b.importance] - importanceOrder[a.importance];
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
    setImportance("important"); // Reset importance
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

  const LoadingIndicator = () => (
    <View className="flex-1 justify-center items-center">
      <ActivityIndicator size="large" color="#4285f4" />
    </View>
  );
  const SortControls = () => {
    return (
      <View className="flex-row justify-end items-center px-4 py-2 bg-gray-50">
        <View className="flex-row items-center">
          <Text className="text-gray-600 mr-2">Sort by:</Text>
          <TouchableOpacity
            className={`px-3 py-1 rounded-l-lg ${
              sortType === "time" ? "bg-blue-500" : "bg-gray-200"
            }`}
            onPress={() => setSortType("time")}
          >
            <Text
              className={sortType === "time" ? "text-white" : "text-gray-600"}
            >
              Time
            </Text>
          </TouchableOpacity>
          <TouchableOpacity
            className={`px-3 py-1 rounded-r-lg ${
              sortType === "importance" ? "bg-blue-500" : "bg-gray-200"
            }`}
            onPress={() => setSortType("importance")}
          >
            <Text
              className={
                sortType === "importance" ? "text-white" : "text-gray-600"
              }
            >
              Importance
            </Text>
          </TouchableOpacity>
          <TouchableOpacity
            className="ml-2 p-2"
            onPress={() =>
              setSortDirection((prev) => (prev === "asc" ? "desc" : "asc"))
            }
          >
            <Ionicons
              name={sortDirection === "asc" ? "arrow-up" : "arrow-down"}
              size={20}
              color="#4B5563"
            />
          </TouchableOpacity>
        </View>
      </View>
    );
  };

  return (
    <View className="flex-1 bg-white">
      <DateNavigator
        selectedDate={selectedDate}
        onDateChange={setSelectedDate}
      />
      <SortControls />
      {isLocalLoading || isLoading ? (
        <LoadingIndicator />
      ) : (
        <ScrollView className="flex-1 px-4">
          {getSortedTasks(filteredTasks).length === 0 ? (
            <Text className="text-gray-500 text-center mt-4">
              No tasks for this day
            </Text>
          ) : (
            getSortedTasks(filteredTasks).map((task: Task) => (
              <View
                key={task.id}
                className={`flex-row items-center justify-between p-4 mb-2 rounded-lg border border-gray-200 ${
                  task.completed ? "bg-gray-100" : "bg-white"
                }`}
                style={{ borderColor: getImportanceColor(task.importance) }}
              >
                <TouchableOpacity
                  className="flex-1 flex-row items-center"
                  onPress={() => toggleTask(task.id)}
                  disabled={isLocalLoading}
                >
                  <View
                    className={`w-6 h-6 border-2 rounded-full mr-2 ${
                      task.completed
                        ? "bg-green-500 border-green-500"
                        : "border-gray-300"
                    }`}
                  >
                    {task.completed && (
                      <Ionicons name="checkmark" size={20} color="white" />
                    )}
                  </View>
                  <View>
                    <Text
                      className={`font-semibold ${
                        task.completed
                          ? "text-gray-500 line-through"
                          : "text-black"
                      }`}
                    >
                      {task.text}
                    </Text>
                    <Text className="text-gray-500 text-sm">
                      {task.startTime} - {task.endTime}
                    </Text>
                  </View>
                </TouchableOpacity>

                <TouchableOpacity
                  className="ml-4"
                  onPress={() => deleteTask(task.id)}
                  disabled={isLocalLoading}
                >
                  <Ionicons name="trash-outline" size={24} color="red" />
                </TouchableOpacity>
              </View>
            ))
          )}
        </ScrollView>
      )}

      <TouchableOpacity
        className="absolute bottom-6 right-6 w-14 h-14 bg-blue-500 rounded-full items-center justify-center shadow-lg"
        onPress={() => setIsModalVisible(true)}
        disabled={isLocalLoading}
      >
        <Ionicons name="add" size={30} color="white" />
      </TouchableOpacity>

      <Modal
        animationType="slide"
        transparent={true}
        visible={isModalVisible}
        onRequestClose={() => {
          setIsModalVisible(false);
          resetForm();
        }}
      >
        <View className="flex-1 justify-end">
          <View className="bg-white p-4 rounded-t-3xl">
            <View className="flex-row justify-between items-center mb-4">
              <Text className="text-xl font-bold">Add New Task</Text>
              <TouchableOpacity
                onPress={() => {
                  setIsModalVisible(false);
                  resetForm();
                }}
              >
                <Ionicons name="close" size={24} color="black" />
              </TouchableOpacity>
            </View>

            <TextInput
              className="border border-gray-300 p-3 rounded-lg mb-4"
              placeholder="Task name"
              value={newTask}
              onChangeText={setNewTask}
            />

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

            {Platform.OS !== "web" && (
              <>
                {Platform.OS === "android" ? (
                  (showStartPicker || showEndPicker) && (
                    <DateTimePicker
                      value={showStartPicker ? startTime : endTime}
                      mode="time"
                      is24Hour={true}
                      onChange={(event, date) =>
                        onTimeChange(
                          event,
                          date,
                          showStartPicker ? "start" : "end",
                        )
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
                        onChange={(event, date) =>
                          onTimeChange(event, date, "start")
                        }
                        style={{ width: 100 }}
                      />
                    )}
                    {showEndPicker && (
                      <DateTimePicker
                        value={endTime}
                        mode="time"
                        is24Hour={true}
                        onChange={(event, date) =>
                          onTimeChange(event, date, "end")
                        }
                        style={{ width: 100 }}
                      />
                    )}
                  </>
                )}
              </>
            )}

            <View className="mb-4">
              <Text className="text-sm text-gray-600 mb-2">
                Importance Level
              </Text>
              <View className="px-2">
                <Slider
                  minimumValue={0}
                  maximumValue={1}
                  step={0.25}
                  value={
                    [
                      "very-important",
                      "important",
                      "mildly-important",
                      "less-important",
                    ].indexOf(importance) / 3
                  }
                  onValueChange={(value) =>
                    setImportance(getImportanceLevel(value))
                  }
                  minimumTrackTintColor={getImportanceColor(importance)}
                  maximumTrackTintColor="#d1d5db"
                  thumbTintColor={getImportanceColor(importance)}
                />
              </View>
              <Text
                className="text-center text-sm mt-2 capitalize"
                style={{ color: getImportanceColor(importance) }}
              >
                {importance.replace("-", " ")}
              </Text>
            </View>

            <TouchableOpacity
              className="bg-blue-500 p-4 rounded-lg mt-4"
              onPress={addTask}
            >
              <Text className="text-white text-center font-bold">Add Task</Text>
            </TouchableOpacity>
          </View>
        </View>
      </Modal>
    </View>
  );
}
