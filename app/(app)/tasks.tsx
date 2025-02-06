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
import { Ionicons } from "@expo/vector-icons";
import { Task } from "@/utils/interfaces";
import DateTimePicker, {
  DateTimePickerEvent,
} from "@react-native-community/datetimepicker";
import { format, addDays } from "date-fns";
import { DateNavigator } from "@/components/DateNavigator";
import { taskService } from "@/utils/taskService";

export default function Tasks() {
  const [tasks, setTasks] = useState<Task[]>([]);
  const [isModalVisible, setIsModalVisible] = useState(false);
  const [selectedDate, setSelectedDate] = useState(new Date());
  const [newTask, setNewTask] = useState<string>("");
  const [startTime, setStartTime] = useState<Date>(new Date());
  const [endTime, setEndTime] = useState<Date>(new Date());
  const [showStartPicker, setShowStartPicker] = useState(false);
  const [showEndPicker, setShowEndPicker] = useState(false);

  useEffect(() => {
    loadTasks();
  }, [selectedDate]);

  const loadTasks = async () => {
    try {
      const loadedTasks = await taskService.fetchTasks(
        format(selectedDate, "yyyy-MM-dd"),
      );
      setTasks(loadedTasks);
    } catch (error) {
      console.error("Error loading tasks:", error);
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
    };

    const updatedTasks = [...tasks, newTaskItem];
    setTasks(updatedTasks);

    try {
      await taskService.saveTasks(updatedTasks, newTaskItem.date);
    } catch (error) {
      console.error("Error saving task:", error);
    }

    setIsModalVisible(false);
    resetForm();
  };

  const toggleTask = async (taskId: number): Promise<void> => {
    const updatedTasks = tasks.map((task) =>
      task.id === taskId ? { ...task, completed: !task.completed } : task,
    );
    setTasks(updatedTasks);

    try {
      await taskService.saveTasks(
        updatedTasks,
        format(selectedDate, "yyyy-MM-dd"),
      );
    } catch (error) {
      console.error("Error updating task:", error);
    }
  };

  const deleteTask = async (taskId: number): Promise<void> => {
    const updatedTasks = tasks.filter((task) => task.id !== taskId);
    setTasks(updatedTasks);

    try {
      await taskService.saveTasks(
        updatedTasks,
        format(selectedDate, "yyyy-MM-dd"),
      );
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
  };
  const filteredAndSortedTasks = tasks
    .filter((task) => task.date === format(selectedDate, "yyyy-MM-dd"))
    .sort((a, b) => a.startTime.localeCompare(b.startTime));

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
    <View className="flex-1 bg-white">
      {/* Header with date navigation */}
      <DateNavigator
        selectedDate={selectedDate}
        onDateChange={setSelectedDate}
      />
      {/* Tasks List */}
      <ScrollView className="flex-1 px-4">
        {filteredAndSortedTasks.length === 0 ? (
          <Text className="text-gray-500 text-center mt-4">
            No tasks for this day
          </Text>
        ) : (
          filteredAndSortedTasks.map((task: Task) => (
            <View
              key={task.id}
              className={`flex-row items-center justify-between p-4 mb-2 rounded-lg border border-gray-200 ${
                task.completed ? "bg-gray-100" : "bg-white"
              }`}
            >
              <TouchableOpacity
                className="flex-1 flex-row items-center"
                onPress={() => toggleTask(task.id)}
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
              >
                <Ionicons name="trash-outline" size={24} color="red" />
              </TouchableOpacity>
            </View>
          ))
        )}
      </ScrollView>

      {/* FAB */}
      <TouchableOpacity
        className="absolute bottom-6 right-6 w-14 h-14 bg-blue-500 rounded-full items-center justify-center shadow-lg"
        onPress={() => setIsModalVisible(true)}
      >
        <Ionicons name="add" size={30} color="white" />
      </TouchableOpacity>

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
        <View className="flex-1 justify-end bg-black/50">
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

            <View className="mb-4">
              <Text className="text-sm text-gray-600 mb-2">Start Time</Text>
              <TouchableOpacity
                className="border border-gray-300 p-3 rounded-lg"
                onPress={() => setShowStartPicker(true)}
              >
                <Text>{format(startTime, "HH:mm")}</Text>
              </TouchableOpacity>
            </View>

            <View className="mb-4">
              <Text className="text-sm text-gray-600 mb-2">End Time</Text>
              <TouchableOpacity
                className="border border-gray-300 p-3 rounded-lg"
                onPress={() => setShowEndPicker(true)}
              >
                <Text>{format(endTime, "HH:mm")}</Text>
              </TouchableOpacity>
            </View>

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
                    onChange={(event, date) => onTimeChange(event, date, "end")}
                    style={{ width: 100 }}
                  />
                )}
              </>
            )}

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
