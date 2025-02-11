import React, { createContext, useContext, useState } from "react";
import { Task } from "@/utils/interfaces";
import { taskService } from "@/utils/taskService";
import { format } from "date-fns";
import { useAuth } from "@/hooks/useAuth";

interface TaskContextType {
  tasksByDate: { [key: string]: Task[] };
  loadTasks: (date: string) => Promise<Task[]>;
  updateTasks: (tasks: Task[], date: string) => Promise<void>;
  isLoading: boolean;
}

const TaskContext = createContext<TaskContextType | undefined>(undefined);

export function TaskProvider({ children }: { children: React.ReactNode }) {
  const { user } = useAuth();
  const [tasksByDate, setTasksByDate] = useState<{ [key: string]: Task[] }>({});
  const [isLoading, setIsLoading] = useState(false);

  const loadTasks = async (date: string) => {
    if (!user) return [];

    setIsLoading(true);
    try {
      const formattedDate = format(new Date(date), "yyyy-MM-dd");

      if (tasksByDate[formattedDate]) {
        return tasksByDate[formattedDate];
      }

      const tasks = await taskService.fetchTasks(formattedDate, user.id);
      setTasksByDate((prev) => ({
        ...prev,
        [formattedDate]: tasks,
      }));
      return tasks;
    } finally {
      setIsLoading(false);
    }
  };

  const updateTasks = async (tasks: Task[], date: string) => {
    if (!user) return;

    const formattedDate = format(new Date(date), "yyyy-MM-dd");
    await taskService.saveTasks(tasks, formattedDate, user.id);
    setTasksByDate((prev) => ({
      ...prev,
      [formattedDate]: tasks,
    }));
  };

  // Clear tasks when user logs out
  React.useEffect(() => {
    if (!user) {
      setTasksByDate({});
    }
  }, [user]);

  return (
    <TaskContext.Provider
      value={{ tasksByDate, loadTasks, updateTasks, isLoading }}
    >
      {children}
    </TaskContext.Provider>
  );
}
export const useTaskContext = () => {
  const context = useContext(TaskContext);
  if (!context) {
    throw new Error("useTaskContext must be used within a TaskProvider");
  }
  return context;
};
