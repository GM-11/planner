import { DateNavigator } from "@/components/DateNavigator";
import { useState } from "react";
import {
  View,
  Text,
  TouchableOpacity,
  ScrollView,
  Modal,
  Pressable,
  TextInput,
} from "react-native";
import { Calendar as RNCalendar } from "react-native-calendars";
import { Plus, ChevronDown, Clock, MapPin } from "lucide-react-native";

type ViewType = "daily" | "weekly" | "monthly";
type EventType = "event" | "task";

interface Event {
  id: string;
  title: string;
  start: Date;
  end: Date;
  type: EventType;
  location?: string;
  description?: string;
  color?: string;
}

export default function Calendar() {
  const [selectedDate, setSelectedDate] = useState(new Date());
  const [viewType, setViewType] = useState<ViewType>("weekly");
  const [events, setEvents] = useState<Event[]>([]);
  const [showNewEventModal, setShowNewEventModal] = useState(false);
  const [selectedTimeSlot, setSelectedTimeSlot] = useState<{
    start: Date;
    end: Date;
  } | null>(null);

  const HOURS = Array.from({ length: 24 }, (_, i) => i);
  const DAYS_OF_WEEK = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];

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

  const TimeSlot = ({ hour, events }: { hour: number; events: Event[] }) => (
    <Pressable
      onPress={() => {
        const start = new Date(selectedDate);
        start.setHours(hour, 0, 0);
        const end = new Date(start);
        end.setHours(hour + 1, 0, 0);
        setSelectedTimeSlot({ start, end });
        setShowNewEventModal(true);
      }}
      className="flex-row h-20 border-t border-gray-100"
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
      <View className="flex-1 border-l border-gray-200">
        {events.map((event) => (
          <View
            key={event.id}
            style={{ backgroundColor: event.color || "#4285f4" }}
            className="absolute m-1 rounded p-2 left-0 right-0"
          >
            <Text className="text-white font-medium">{event.title}</Text>
            {event.location && (
              <View className="flex-row items-center mt-1">
                <MapPin size={12} color="white" />
                <Text className="text-white text-xs ml-1">
                  {event.location}
                </Text>
              </View>
            )}
          </View>
        ))}
      </View>
    </Pressable>
  );

  const NewEventModal = () => (
    <Modal
      visible={showNewEventModal}
      animationType="slide"
      transparent
      onRequestClose={() => setShowNewEventModal(false)}
    >
      <View className="flex-1 justify-end">
        <View className="bg-white rounded-t-xl shadow-lg">
          <View className="p-4 border-b border-gray-200">
            <View className="flex-row justify-between items-center">
              <Text className="text-xl font-semibold">New event</Text>
              <TouchableOpacity
                onPress={() => setShowNewEventModal(false)}
                className="p-2"
              >
                <Text className="text-blue-600">Cancel</Text>
              </TouchableOpacity>
            </View>

            {/* Event Form */}
            <View className="space-y-4 mt-4">
              <View className="border-b border-gray-200 pb-2">
                <TextInput
                  placeholder="Add title"
                  className="text-lg"
                  placeholderTextColor="#666"
                />
              </View>

              <View className="flex-row items-center space-x-2">
                <Clock size={20} color="#666" />
                <Text>
                  {selectedTimeSlot?.start.toLocaleTimeString()} -{" "}
                  {selectedTimeSlot?.end.toLocaleTimeString()}
                </Text>
              </View>

              <View className="flex-row items-center space-x-2">
                <MapPin size={20} color="#666" />
                <TextInput
                  placeholder="Add location"
                  className="flex-1"
                  placeholderTextColor="#666"
                />
              </View>

              <TouchableOpacity
                className="bg-blue-600 p-3 rounded-lg mt-4"
                onPress={() => {
                  // Handle event creation
                  setShowNewEventModal(false);
                }}
              >
                <Text className="text-white text-center font-medium">Save</Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </View>
    </Modal>
  );

  const renderDailyView = () => (
    <ScrollView>
      {HOURS.map((hour) => (
        <TimeSlot
          key={hour}
          hour={hour}
          events={events.filter((event) => {
            const eventHour = event.start.getHours();
            return (
              eventHour === hour &&
              event.start.toDateString() === selectedDate.toDateString()
            );
          })}
        />
      ))}
    </ScrollView>
  );

  const renderWeeklyView = () => (
    <View className="flex-1">
      <View className="flex-row border-b border-gray-200">
        <View className="w-16" /> {/* Time column spacer */}
        {DAYS_OF_WEEK.map((day) => (
          <View key={day} className="flex-1 p-2 items-center">
            <Text className="text-gray-500">{day}</Text>
          </View>
        ))}
      </View>
      <ScrollView>
        {HOURS.map((hour) => (
          <TimeSlot
            key={hour}
            hour={hour}
            events={events.filter((event) => event.start.getHours() === hour)}
          />
        ))}
      </ScrollView>
    </View>
  );

  const renderMonthlyView = () => (
    <RNCalendar
      onDayPress={(day) => {
        setSelectedDate(new Date(day.timestamp));
        setViewType("daily");
      }}
      markedDates={events.reduce((acc, event) => {
        const dateStr = event.start.toISOString().split("T")[0];
        return {
          ...acc,
          [dateStr]: { marked: true, dotColor: event.color || "#4285f4" },
        };
      }, {})}
    />
  );

  return (
    <View className="flex-1 bg-white">
      <ViewSelector />

      {viewType === "daily" && renderDailyView()}
      {viewType === "weekly" && renderWeeklyView()}
      {viewType === "monthly" && renderMonthlyView()}

      <TouchableOpacity
        onPress={() => setShowNewEventModal(true)}
        className="absolute bottom-6 right-6 w-14 h-14 bg-blue-600 rounded-full items-center justify-center shadow-lg"
      >
        <Plus color="white" size={24} />
      </TouchableOpacity>

      <NewEventModal />
    </View>
  );
}
