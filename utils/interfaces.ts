export interface Task {
  id: number;
  text: string;
  startTime: string;
  endTime: string;
  date: string;
  completed: boolean;
  importance:
    | "very-important"
    | "important"
    | "mildly-important"
    | "less-important";
}
export interface User {
  id: string;
  email?: string;
  user_metadata?: {
    full_name?: string;
    avatar_url?: string;
  };
}

export interface AuthError {
  message: string;
}
