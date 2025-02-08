import { supabase } from "@/utils/supabase";
import { Task } from "@/utils/interfaces";
import { format } from "date-fns";

interface CompressedTaskData {
  t: string; // text
  s: string; // start time
  e: string; // end time
  c: boolean; // completed
  i: string; // importance
}

export const taskService = {
  // Compress task data before storing
  compressTasks(tasks: Task[]): CompressedTaskData[] {
    return tasks.map((task) => ({
      t: task.text,
      s: task.startTime,
      e: task.endTime,
      c: task.completed,
      i: task.importance,
    }));
  },

  // Decompress task data after retrieving
  decompressTasks(data: CompressedTaskData[], date: string): Task[] {
    return data.map((item, index) => ({
      id: Date.now() + index,
      text: item.t,
      startTime: item.s,
      endTime: item.e,
      completed: item.c,
      date,
      importance: item.i as Task["importance"],
    }));
  },

  // Save tasks for a specific date
  async saveTasks(tasks: Task[], date: string, userId: string) {
    const compressed = this.compressTasks(tasks);

    if (tasks.length === 0) {
      const { error } = await supabase
        .from("tasks")
        .delete()
        .eq("user_id", userId)
        .eq("date", format(new Date(date), "yyyy-MM-dd"));

      if (error) throw error;
    } else {
      const { error } = await supabase.from("tasks").upsert(
        {
          user_id: userId,
          date: format(new Date(date), "yyyy-MM-dd"),
          data: compressed,
          updated_at: new Date().toISOString(),
        },
        {
          onConflict: "user_id,date",
        },
      );

      if (error) throw error;
    }
  },

  // Fetch tasks for a specific date
  async fetchTasks(date: string, userId: string): Promise<Task[]> {
    const { data, error } = await supabase
      .from("tasks")
      .select("data")
      .eq("user_id", userId)
      .eq("date", format(new Date(date), "yyyy-MM-dd"))
      .maybeSingle();

    if (error) throw error;

    return data ? this.decompressTasks(data.data, date) : [];
  },
};
