import { View, Animated, Easing, Dimensions } from "react-native";
import { useEffect, useRef } from "react";
import { LinearGradient } from "expo-linear-gradient";

const { width: SCREEN_WIDTH } = Dimensions.get("window");

interface ShimmerProps {
  width: number | string;
  height: number | string;
  borderRadius?: number;
  style?: any;
}

export const Shimmer = ({
  width,
  height,
  borderRadius = 8,
  style,
}: ShimmerProps) => {
  // Convert string width to number if percentage
  const shimmerWidth =
    typeof width === "string" && width.includes("%")
      ? SCREEN_WIDTH * (parseInt(width) / 100)
      : width;

  const translateX = useRef(
    new Animated.Value(
      -(typeof shimmerWidth === "number" ? shimmerWidth : SCREEN_WIDTH),
    ),
  ).current;

  useEffect(() => {
    const shimmerAnimation = Animated.loop(
      Animated.sequence([
        Animated.timing(translateX, {
          toValue:
            typeof shimmerWidth === "number" ? shimmerWidth : SCREEN_WIDTH,
          duration: 1200,
          easing: Easing.linear,
          useNativeDriver: true,
        }),
        Animated.timing(translateX, {
          toValue: -(typeof shimmerWidth === "number"
            ? shimmerWidth
            : SCREEN_WIDTH),
          duration: 0,
          useNativeDriver: true,
        }),
      ]),
    );

    shimmerAnimation.start();

    return () => shimmerAnimation.stop();
  }, [shimmerWidth]);

  return (
    <View
      style={[
        {
          width,
          height,
          backgroundColor: "#E2E8F0",
          overflow: "hidden",
          borderRadius,
        },
        style,
      ]}
    >
      <Animated.View
        style={{
          width: "100%",
          height: "100%",
          transform: [{ translateX }],
        }}
      >
        <LinearGradient
          colors={[
            "rgba(126, 34, 206, 0.02)", // primary-600 with opacity
            "rgba(126, 34, 206, 0.10)", // primary-600 with opacity
            "rgba(126, 34, 206, 0.02)", // primary-600 with opacity
          ]}
          start={{ x: 0, y: 0 }}
          end={{ x: 1, y: 0 }}
          style={{
            width: "100%",
            height: "100%",
          }}
        />
      </Animated.View>
    </View>
  );
};
