import React, { createContext, useState, useEffect } from "react";
import { Alert } from "react-native";
import { Session, User, AuthError } from "@supabase/supabase-js";
import { supabase } from "../utils/supabase";

interface AuthState {
  user: User | null;
  session: Session | null;
  loading: boolean;
  initialized: boolean;
}

interface AuthContextType extends AuthState {
  signUp: (email: string, password: string) => Promise<void>;
  signIn: (email: string, password: string) => Promise<void>;
  signInWithGoogle: () => Promise<void>;
  signOut: () => Promise<void>;
  forgotPassword: (email: string) => Promise<void>;
  resetPassword: (newPassword: string) => Promise<void>;
  updateProfile: (data: {
    full_name?: string;
    avatar_url?: string;
  }) => Promise<void>;
}

export const AuthContext = createContext<AuthContextType>(
  {} as AuthContextType,
);

interface AuthProviderProps {
  children: React.ReactNode;
}

export function AuthProvider({ children }: AuthProviderProps) {
  const [state, setState] = useState<AuthState>({
    user: null,
    session: null,
    loading: true,
    initialized: false,
  });

  // Initialize auth state with session check
  useEffect(() => {
    supabase.auth.getSession().then(({ data: { session } }) => {
      setState((current) => ({
        ...current,
        user: session?.user ?? null,
        session,
        loading: false,
        initialized: true,
      }));
    });

    // Listen for auth changes
    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange(async (event, session) => {
      console.log("Auth state changed:", event);
      setState((current) => ({
        ...current,
        user: session?.user ?? null,
        session,
        loading: false,
      }));
    });

    return () => {
      subscription.unsubscribe();
    };
  }, []);

  // Sign up with email and password
  async function signUp(email: string, password: string) {
    try {
      setState((current) => ({ ...current, loading: true }));

      const { error, data } = await supabase.auth.signUp({
        email,
        password,
      });

      console.log(data);

      if (error) throw error;

      Alert.alert(
        "Verification Required",
        "Please check your email to verify your account",
      );
    } catch (error) {
      const authError = error as AuthError;
      console.error("Sign up error:", authError);
      Alert.alert("Error", authError.message);
      throw error;
    } finally {
      setState((current) => ({ ...current, loading: false }));
    }
  }

  // Sign in with email and password
  async function signIn(email: string, password: string) {
    try {
      setState((current) => ({ ...current, loading: true }));

      const { error, data } = await supabase.auth.signInWithPassword({
        email,
        password,
      });

      console.log(data);

      if (error) throw error;
    } catch (error) {
      const authError = error as AuthError;
      console.error("Sign in error:", authError);
      Alert.alert("Error", authError.message);
      throw error;
    } finally {
      setState((current) => ({ ...current, loading: false }));
    }
  }

  // Sign in with Google
  const signInWithGoogle = async () => {
    try {
      setState((current) => ({ ...current, loading: true }));

      const { error } = await supabase.auth.signInWithOAuth({
        provider: "google",
        options: {
          redirectTo: "your-app-scheme://auth/callback",
        },
      });

      if (error) throw error;
    } catch (error) {
      const authError = error as AuthError;
      console.error("Google sign in error:", authError);
      Alert.alert("Error", authError.message);
      throw error;
    } finally {
      setState((current) => ({ ...current, loading: false }));
    }
  };

  // Sign out
  const signOut = async () => {
    try {
      setState((current) => ({ ...current, loading: true }));

      const { error } = await supabase.auth.signOut();
      if (error) throw error;
    } catch (error) {
      const authError = error as AuthError;
      console.error("Sign out error:", authError);
      Alert.alert("Error", authError.message);
      throw error;
    } finally {
      setState((current) => ({ ...current, loading: false }));
    }
  };

  // Forgot password
  const forgotPassword = async (email: string) => {
    try {
      setState((current) => ({ ...current, loading: true }));

      const { error } = await supabase.auth.resetPasswordForEmail(email, {
        redirectTo: "your-app-scheme://auth/reset-password",
      });

      if (error) throw error;

      Alert.alert(
        "Password Reset",
        "Check your email for the password reset link",
      );
    } catch (error) {
      const authError = error as AuthError;
      console.error("Password reset error:", authError);
      Alert.alert("Error", authError.message);
      throw error;
    } finally {
      setState((current) => ({ ...current, loading: false }));
    }
  };

  // Reset password
  const resetPassword = async (newPassword: string) => {
    try {
      setState((current) => ({ ...current, loading: true }));

      const { error } = await supabase.auth.updateUser({
        password: newPassword,
      });

      if (error) throw error;

      Alert.alert("Success", "Your password has been updated");
    } catch (error) {
      const authError = error as AuthError;
      console.error("Password update error:", authError);
      Alert.alert("Error", authError.message);
      throw error;
    } finally {
      setState((current) => ({ ...current, loading: false }));
    }
  };

  // Update user profile
  const updateProfile = async (data: {
    full_name?: string;
    avatar_url?: string;
  }) => {
    try {
      setState((current) => ({ ...current, loading: true }));

      const { error } = await supabase.auth.updateUser({
        data: data,
      });

      if (error) throw error;

      Alert.alert("Success", "Profile updated successfully");
    } catch (error) {
      const authError = error as AuthError;
      console.error("Profile update error:", authError);
      Alert.alert("Error", authError.message);
      throw error;
    } finally {
      setState((current) => ({ ...current, loading: false }));
    }
  };

  // Don't render until we have initialized auth
  if (!state.initialized) {
    return null; // Or a loading screen
  }

  return (
    <AuthContext.Provider
      value={{
        ...state,
        signUp,
        signIn,
        signInWithGoogle,
        signOut,
        forgotPassword,
        resetPassword,
        updateProfile,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}
