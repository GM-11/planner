interface Task {
  id: string;
  name: string;
  date: string;
  time: string;
  duration: string;
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
