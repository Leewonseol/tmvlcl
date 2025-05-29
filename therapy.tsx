// client/src/pages/therapy.tsx (또는 해당 파일 경로)

import { useState } from "react";
// import { useQuery } from "@tanstack/react-query"; // useQuery가 더 이상 사용되지 않음
import MoodCheckIn from "@/components/MoodCheckIn";
import ProgressDashboard from "@/components/ProgressDashboard";
import { Heart, User } from "lucide-react";
// import type { UserProgress } from "@shared/schema"; // UserProgress 타입 import 제거

export default function TherapyPage() {
  const [selectedMood, setSelectedMood] = useState<string | null>(null);

  // '/api/progress' 데이터 호출 제거됨 (헤더에서 '연속 기록'이 사라졌으므로)
  // const { data: progress } = useQuery<UserProgress>({
  //   queryKey: ["/api/progress"],
  // });

  // '/api/mood' 관련 'moodEntries' 데이터 호출은 이미 제거됨

  return (
    <div className="min-h-screen bg-gradient-to-br from-background to-secondary/10">
      {/* Header */}
      <header className="bg-white/80 backdrop-blur-sm border-b border-border sticky top-0 z-50">
        <div className="max-w-6xl mx-auto px-4 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-3">
              <div className="w-10 h-10 bg-gradient-to-r from-primary to-secondary rounded-full flex items-center justify-center">
                <Heart className="text-white w-5 h-5" />
              </div>
              <h1 className="text-xl font-semibold text-foreground">마음챙김</h1>
            </div>
            <div className="flex items-center space-x-4">
              {/* 헤더에서 '연속 기록' 표시 부분 제거됨 */}
              {/*
              <div className="hidden md:flex items-center space-x-2 text-sm text-muted-foreground">
                <span className="text-primary">🔥</span>
                <span>{progress?.streakDays || 0}일 연속</span>
              </div>
              */}
              <button className="w-8 h-8 bg-muted rounded-full flex items-center justify-center hover:bg-muted/80 transition-colors">
                <User className="w-4 h-4 text-muted-foreground" />
              </button>
            </div>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-6xl mx-auto px-4 py-8 space-y-12">
        <MoodCheckIn 
          selectedMood={selectedMood} 
          onMoodSelect={setSelectedMood}
          onStageComplete={() => {
            // console.log("MoodCheckIn stage completed");
          }}
        />

        {/* ProgressDashboard는 이제 제목과 설명 외에는 내용을 표시하지 않거나, 비어있는 grid를 표시합니다. */}
        <ProgressDashboard />
      </main>

      {/* Floating Action Button */}
      <button className="fixed bottom-6 right-6 w-14 h-14 bg-gradient-to-r from-primary to-secondary rounded-full shadow-lg hover:shadow-xl transition-all duration-200 flex items-center justify-center group z-40">
        <span className="text-white text-xl group-hover:rotate-90 transition-transform duration-200">+</span>
      </button>
    </div>
  );
}
