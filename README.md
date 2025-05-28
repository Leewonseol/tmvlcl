import { useState } from "react";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { apiRequest } from "@/lib/queryClient";
import { useToast } from "@/hooks/use-toast";
import { cn, getMoodScore } from "@/lib/utils";
import { Sun } from "lucide-react";
import { Button } from "@/components/ui/button";

interface MoodCheckInProps {
  selectedMood: string | null;
  onMoodSelect: (mood: string) => void;
  onStageComplete: (hasNegativeThoughts: boolean) => void;
}

const moodOptions = [
  { label: "매우나쁨", emoji: "😢" },
  { label: "나쁨", emoji: "😟" },
  { label: "보통", emoji: "😐" },
  { label: "좋음", emoji: "😊" },
  { label: "매우좋음", emoji: "😄" },
];

export default function MoodCheckIn({
  selectedMood,
  onMoodSelect,
  onStageComplete,
}: MoodCheckInProps) {
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [todayDescription, setTodayDescription] = useState("");
  const [supportEvidence, setSupportEvidence] = useState("");
  const [opposingEvidence, setOpposingEvidence] = useState("");
  const [newConclusion, setNewConclusion] = useState("");
  const [gratefulExperience, setGratefulExperience] = useState("");
  const [tomorrowPlan, setTomorrowPlan] = useState("");
  const [importantTasks, setImportantTasks] = useState(["", "", ""]);
  const [timeBlocks, setTimeBlocks] = useState<{
    [key: string]: { morning: string; afternoon: string };
  }>({});
  const queryClient = useQueryClient();
  const { toast } = useToast();

  const moodMutation = useMutation({
    mutationFn: async (mood: string) => {
      const response = await apiRequest("POST", "/api/mood", {
        mood,
        moodScore: getMoodScore(mood),
        todayDescription,
        supportEvidence,
        opposingEvidence,
        newConclusion,
        gratefulExperience,
        tomorrowPlan,
        importantTasks: JSON.stringify(importantTasks),
        timeBlocks: JSON.stringify(timeBlocks),
      });
      return response.json();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/mood"] });
      queryClient.invalidateQueries({ queryKey: ["/api/progress"] });
      toast({
        title: "오늘의 하루 기록이 완료되었습니다",
        description: "감정 분석과 계획이 저장되었어요.",
      });
      setIsSubmitting(false);
      onStageComplete(false);
    },
    onError: () => {
      toast({
        title: "기록 실패",
        description: "기록 저장 중 오류가 발생했습니다.",
        variant: "destructive",
      });
      setIsSubmitting(false);
    },
  });

  const handleMoodSelect = (mood: string) => {
    onMoodSelect(mood);
  };

  const handleSubmit = () => {
    if (!selectedMood) {
      toast({ title: "기분을 선택해주세요", variant: "destructive" });
      return;
    }
    if (!todayDescription.trim()) {
      toast({ title: "오늘 하루 이야기를 입력해주세요", variant: "destructive" });
      return;
    }
    if (!newConclusion.trim()) {
      toast({ title: "새로운 결론을 입력해주세요", variant: "destructive" });
      return;
    }
    if (!gratefulExperience.trim()) {
      toast({ title: "감사한 경험을 입력해주세요", variant: "destructive" });
      return;
    }
    if (!tomorrowPlan.trim()) {
      toast({ title: "내일의 행동 계획을 입력해주세요", variant: "destructive" });
      return;
    }

    setIsSubmitting(true);
    moodMutation.mutate(selectedMood);
  };

  return (
    <section className="mb-12 animate-fade-in">
      <div className="text-center mb-8">
        <div className="inline-flex items-center justify-center w-16 h-16 bg-gradient-to-r from-primary to-secondary rounded-full mb-4 animate-pulse-gentle">
          <Sun className="text-white w-8 h-8" />
        </div>
        <h2 className="text-3xl font-bold text-foreground mb-2">오늘의 하루</h2>
        <p className="text-muted-foreground">오늘 하루를 정리하고 내일을 계획해보세요</p>
      </div>

      <div className="max-w-3xl mx-auto space-y-6">
        {/* 기분 선택 및 하루 이야기 */}
        <div className="therapy-card">
          <h3 className="text-lg font-semibold text-foreground mb-4">오늘 하루는 어땠나요?</h3>
          <div className="mb-6">
            <p className="text-sm font-medium text-foreground mb-3">감정 선택:</p>
            <div className="grid grid-cols-2 md:grid-cols-5 gap-3 mb-6">
              {moodOptions.map((mood) => (
                <button
                  key={mood.label}
                  onClick={() => handleMoodSelect(mood.label)}
                  className={cn("mood-button group", selectedMood === mood.label && "selected")}
                >
                  <div className="text-2xl mb-1 group-hover:scale-110 transition-transform duration-200">
                    {mood.emoji}
                  </div>
                  <div className="text-xs font-medium text-foreground group-hover:text-primary">
                    {mood.label}
                  </div>
                </button>
              ))}
            </div>

            <div>
              <label className="block text-sm font-medium text-foreground mb-2">
                오늘 하루를 자세히 들려주세요:
              </label>
              <textarea
                value={todayDescription}
                onChange={(e) => setTodayDescription(e.target.value)}
                placeholder="오늘 있었던 일, 느꼈던 감정, 생각들을 자유롭게 적어보세요..."
                className="w-full p-3 border border-border rounded-lg resize-none focus:ring-2 focus:ring-primary focus:border-transparent"
                rows={4}
              />
            </div>
          </div>
        </div>

        {/* 감정 원인 분석 */}
        <div className="therapy-card">
          <h3 className="text-lg font-semibold text-foreground mb-4">그 감정을 왜 느꼈을까요?</h3>
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-foreground mb-2">지지 증거:</label>
              <textarea
                value={supportEvidence}
                onChange={(e) => setSupportEvidence(e.target.value)}
                placeholder="이 감정을 뒷받침하는 객관적 사실들을 적어보세요..."
                className="w-full p-3 border border-border rounded-lg resize-none focus:ring-2 focus:ring-primary focus:border-transparent"
                rows={2}
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-foreground mb-2">반대 증거:</label>
              <textarea
                value={opposingEvidence}
                onChange={(e) => setOpposingEvidence(e.target.value)}
                placeholder="이 감정에 반대되는 증거나 다른 관점을 적어보세요..."
                className="w-full p-3 border border-border rounded-lg resize-none focus:ring-2 focus:ring-primary focus:border-transparent"
                rows={2}
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-foreground mb-2">새로운 결론:</label>
              <textarea
                value={newConclusion}
                onChange={(e) => setNewConclusion(e.target.value)}
                placeholder="위의 분석을 토대로 새로운 관점이나 결론을 적어보세요..."
                className="w-full p-3 border border-border rounded-lg resize-none focus:ring-2 focus:ring-primary focus:border-transparent"
                rows={2}
              />
            </div>
          </div>
        </div>

        {/* 감사한 경험 */}
        <div className="therapy-card">
          <h3 className="text-lg font-semibold text-foreground mb-4">감사한 경험</h3>
          <div>
            <label className="block text-sm font-medium text-foreground mb-2">
              오늘 감사했던 일 (최소 1개):
            </label>
            <textarea
              value={gratefulExperience}
              onChange={(e) => setGratefulExperience(e.target.value)}
              placeholder="오늘 하루 중 감사했던 일, 긍정적인 경험을 적어보세요..."
              className="w-full p-3 border border-border rounded-lg resize-none focus:ring-2 focus:ring-primary focus:border-transparent"
              rows={2}
            />
          </div>
        </div>

        {/* 내일 계획 */}
        <div className="therapy-card">
          <h3 className="text-lg font-semibold text-foreground mb-4">내일의 행동 계획</h3>
          <div>
            <label className="block text-sm font-medium text-foreground mb-2">계획:</label>
            <textarea
              value={tomorrowPlan}
              onChange={(e) => setTomorrowPlan(e.target.value)}
              placeholder="내일 무엇을 실천할지 적어보세요..."
              className="w-full p-3 border border-border rounded-lg resize-none focus:ring-2 focus:ring-primary focus:border-transparent"
              rows={2}
            />
          </div>
        </div>

        <div className="text-center mt-8">
          <Button onClick={handleSubmit} disabled={isSubmitting}>
            {isSubmitting ? "기록 중..." : "기록 완료"}
          </Button>
        </div>
      </div>
    </section>
  );
}
