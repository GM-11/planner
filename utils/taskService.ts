import { supabase } from "@/utils/supabase";
import { Task } from "@/utils/interfaces";
import { format } from "date-fns";

interface CompressedTaskData {
  t: string; // text
  s: string; // start time
  e: string; // end time
  c: boolean; // completed
}

export const taskService = {
  // Compress task data before storing
  compressTasks(tasks: Task[]): CompressedTaskData[] {
    return tasks.map((task) => ({
      t: task.text,
      s: task.startTime,
      e: task.endTime,
      c: task.completed,
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
    }));
  },

  // Save tasks for a specific date
  async saveTasks(tasks: Task[], date: string) {
    const compressed = this.compressTasks(tasks);
    const userId = (await supabase.auth.getUser()).data.user?.id;

    if (tasks.length === 0) {
      // If there are no tasks, delete the record for this date
      const { error } = await supabase
        .from("tasks")
        .delete()
        .eq("user_id", userId)
        .eq("date", format(new Date(date), "yyyy-MM-dd"));

      if (error) throw error;
    } else {
      // If there are tasks, upsert them
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
  async fetchTasks(date: string): Promise<Task[]> {
    const { data, error } = await supabase
      .from("tasks")
      .select("data")
      .eq("user_id", (await supabase.auth.getUser()).data.user?.id)
      .eq("date", format(new Date(date), "yyyy-MM-dd"))
      .maybeSingle(); // Use maybeSingle() instead of single()

    if (error) throw error;

    // If no data exists for this date, return empty array
    return data ? this.decompressTasks(data.data, date) : [];
  },
};
