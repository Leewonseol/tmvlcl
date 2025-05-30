import { useState } from "react";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { apiRequest } from "@/lib/queryClient"; // 가정한 경로
import { useToast } from "@/hooks/use-toast"; // 가정한 경로
import { cn, getMoodScore } from "@/lib/utils"; // 가정한 경로
import { Sun } from "lucide-react";
import { Button } from "@/components/ui/button"; // 가정한 경로

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
  // 아래 importantTasks와 timeBlocks는 현재 UI에서는 사용되지 않지만,
  // API 요청에는 포함되어 있으므로 일단 유지합니다.
  // 필요 없다면 제거하거나, 관련 UI를 추가해야 합니다.
  const [importantTasks, setImportantTasks] = useState(["", "", ""]);
  const [timeBlocks, setTimeBlocks] = useState<{
    [key: string]: { morning: string; afternoon: string };
  }>({});
  const queryClient = useQueryClient();
  const { toast } = useToast();

  const moodMutation = useMutation({
    mutationFn: async (mood: string) => {
      const response = await apiRequest("POST", "/api/mood", { // API 엔드포인트 확인 필요
        mood,
        moodScore: getMoodScore(mood), // getMoodScore 함수 구현 필요
        todayDescription,
        supportEvidence,
        opposingEvidence,
        newConclusion,
        gratefulExperience,
        tomorrowPlan,
        importantTasks: JSON.stringify(importantTasks),
        timeBlocks: JSON.stringify(timeBlocks),
      });
      // apiRequest가 이미 response.json()을 처리한다면 아래 .json() 호출은 제거해야 할 수 있습니다.
      // 라이브러리 문서를 확인하세요.
      if (!response.ok) throw new Error("Network response was not ok");
      return response.json();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/mood"] }); // queryKey를 배열로 감싸야 합니다.
      queryClient.invalidateQueries({ queryKey: ["/api/progress"] }); // queryKey를 배열로 감싸야 합니다.
      toast({
        title: "오늘의 하루 기록이 완료되었습니다",
        description: "감정 분석과 계획이 저장되었어요.",
      });
      setIsSubmitting(false);
      onStageComplete(false); // 혹은 적절한 값 전달
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
    // supportEvidence, opposingEvidence는 필수값이 아닌 것으로 보입니다.
    // 필요하다면 유효성 검사를 추가하세요.
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
        <div className="therapy-card p-6 bg-card rounded-lg shadow"> {/* therapy-card 스타일을 위해 p-6 bg-card rounded-lg shadow 추가 */}
          <h3 className="text-lg font-semibold text-foreground mb-4">오늘 하루는 어땠나요?</h3>
          <div className="mb-6">
            <p className="text-sm font-medium text-foreground mb-3">감정 선택:</p>
            <div className="grid grid-cols-2 md:grid-cols-5 gap-3 mb-6">
              {moodOptions.map((mood) => (
                <button
                  key={mood.label}
                  onClick={() => handleMoodSelect(mood.label)}
                  className={cn(
                    "mood-button group p-3 border rounded-lg flex flex-col items-center justify-center transition-all duration-200 hover:shadow-md", // mood-button 스타일 추가
                    selectedMood === mood.label
                      ? "bg-primary text-primary-foreground border-primary ring-2 ring-primary ring-offset-2" // selected 스타일 추가
                      : "bg-background hover:bg-muted"
                  )}
                >
                  <div className="text-3xl mb-1 group-hover:scale-110 transition-transform duration-200">
                    {mood.emoji}
                  </div>
                  <div className="text-xs font-medium text-foreground group-hover:text-primary">
                    {mood.label}
                  </div>
                </button>
              ))}
            </div>

            <div>
              <label htmlFor="todayDescription" className="block text-sm font-medium text-foreground mb-2">
                오늘 하루를 자세히 들려주세요:
              </label>
              <textarea
                id="todayDescription"
                value={todayDescription}
                onChange={(e) => setTodayDescription(e.target.value)}
                placeholder="오늘 있었던 일, 느꼈던 감정, 생각들을 자유롭게 적어보세요..."
                className="w-full p-3 border border-border rounded-lg resize-none focus:ring-2 focus:ring-primary focus:border-transparent bg-input text-foreground placeholder-muted-foreground" // 스타일 추가
                rows={4}
              />
            </div>
          </div>
        </div>

        {/* 감정 원인 분석 */}
        <div className="therapy-card p-6 bg-card rounded-lg shadow"> {/* therapy-card 스타일 추가 */}
          <h3 className="text-lg font-semibold text-foreground mb-4">그 감정을 왜 느꼈을까요?</h3>
          <div className="space-y-4">
            <div>
              <label htmlFor="supportEvidence" className="block text-sm font-medium text-foreground mb-2">지지 근거:</label>
              <textarea
                id="supportEvidence"
                value={supportEvidence}
                onChange={(e) => setSupportEvidence(e.target.value)}
                placeholder="이 감정을 뒷받침하는 사실들을 적어보세요..."
                className="w-full p-3 border border-border rounded-lg resize-none focus:ring-2 focus:ring-primary focus:border-transparent bg-input text-foreground placeholder-muted-foreground" // 스타일 추가
                rows={2}
              />
            </div>
            <div>
              <label htmlFor="opposingEvidence" className="block text-sm font-medium text-foreground mb-2">반대 근거:</label>
              <textarea
                id="opposingEvidence"
                value={opposingEvidence}
                onChange={(e) => setOpposingEvidence(e.target.value)}
                placeholder="감정을 뒷받침하는 사실들에 반대되는 관점을 적어보세요..."
                className="w-full p-3 border border-border rounded-lg resize-none focus:ring-2 focus:ring-primary focus:border-transparent bg-input text-foreground placeholder-muted-foreground" // 스타일 추가
                rows={2}
              />
            </div>
            <div>
              <label htmlFor="newConclusion" className="block text-sm font-medium text-foreground mb-2">새로운 결론:</label>
              <textarea
                id="newConclusion"
                value={newConclusion}
                onChange={(e) => setNewConclusion(e.target.value)}
                placeholder="위의 분석을 토대로 새로운 관점이나 결론을 적어보세요..."
                className="w-full p-3 border border-border rounded-lg resize-none focus:ring-2 focus:ring-primary focus:border-transparent bg-input text-foreground placeholder-muted-foreground" // 스타일 추가
                rows={2}
              />
            </div>
          </div>
        </div>

        {/* 감사한 경험 */}
        <div className="therapy-card p-6 bg-card rounded-lg shadow"> {/* therapy-card 스타일 추가 */}
          <h3 className="text-lg font-semibold text-foreground mb-4">감사한 경험</h3>
          <div>
            <label htmlFor="gratefulExperience" className="block text-sm font-medium text-foreground mb-2">
              오늘 감사했던 일 (최소 1개):
            </label>
            <textarea
              id="gratefulExperience"
              value={gratefulExperience}
              onChange={(e) => setGratefulExperience(e.target.value)}
              placeholder="오늘 하루 중 감사했던 일, 긍정적인 경험을 적어보세요..."
              className="w-full p-3 border border-border rounded-lg resize-none focus:ring-2 focus:ring-primary focus:border-transparent bg-input text-foreground placeholder-muted-foreground" // 스타일 추가
              rows={2}
            />
          </div>
        </div>

        {/* 내일 계획 */}
        <div className="therapy-card p-6 bg-card rounded-lg shadow"> {/* therapy-card 스타일 추가 */}
          <h3 className="text-lg font-semibold text-foreground mb-4">내일의 행동 계획</h3>
          <div>
            <label htmlFor="tomorrowPlan" className="block text-sm font-medium text-foreground mb-2">계획:</label>
            <textarea
              id="tomorrowPlan"
              value={tomorrowPlan}
              onChange={(e) => setTomorrowPlan(e.target.value)}
              placeholder="내일 무엇을 할지 적어보세요..."
              className="w-full p-3 border border-border rounded-lg resize-none focus:ring-2 focus:ring-primary focus:border-transparent bg-input text-foreground placeholder-muted-foreground" // 스타일 추가
              rows={2}
            />
          </div>
        </div>

        <div className="text-center mt-8">
          <Button onClick={handleSubmit} disabled={isSubmitting} size="lg"> {/* size="lg"로 버튼 크기 조정 */}
            {isSubmitting ? "기록 중..." : "기록 완료"}
          </Button>
        </div>

        {/* --- 심리상담 전문가 찾기 섹션 추가 --- */}
        <div className="mt-12 border-t border-border pt-8"> {/* 위쪽 여백 및 구분선 스타일 개선 */}
          <h2 className="text-xl font-semibold text-foreground mb-6 text-center md:text-left"> {/* 제목 스타일 및 정렬 */}
            🧠 심리상담 전문가 찾기
          </h2>
          <ul className="space-y-3 list-disc list-inside text-muted-foreground"> {/* 링크 스타일 개선 */}
            <li>
              <a
                href="https://krcpa.or.kr/user/new/sub04_1new.asp"
                target="_blank"
                rel="noopener noreferrer"
                className="text-blue-600 hover:text-blue-700 hover:underline dark:text-blue-400 dark:hover:text-blue-500"
              >
                한국상담심리학회 상담심리사 찾아보기
              </a>
            </li>
            <li>
              <a
                href="https://counselors.or.kr/KOR/user/find_counselors.php"
                target="_blank"
                rel="noopener noreferrer"
                className="text-blue-600 hover:text-blue-700 hover:underline dark:text-blue-400 dark:hover:text-blue-500"
              >
                한국상담학회 전문상담사 찾기
              </a>
            </li>
            <li>
              <a
                href="https://www.kcp.or.kr/new/psychologistManagement/list.asp?listType=1"
                target="_blank"
                rel="noopener noreferrer"
                className="text-blue-600 hover:text-blue-700 hover:underline dark:text-blue-400 dark:hover:text-blue-500"
              >
                한국임상심리학회 임상심리전문가 조회
              </a>
            </li>
            <li>
              <a
                href="https://www.socialservice.or.kr:444/user/svcsrch/supply/supplyList.do"
                target="_blank"
                rel="noopener noreferrer"
                className="text-blue-600 hover:text-blue-700 hover:underline dark:text-blue-400 dark:hover:text-blue-500"
              >
                전국민 마음투자 지원사업 제공기관
              </a>
            </li>
          </ul>
        </div>
{/* --- 정신건강복지센터 찾기 섹션 추가 --- */}
<div className="mt-12 border-t border-border pt-8">
  <h2 className="text-xl font-semibold text-foreground mb-6 text-center md:text-left">
    🏥 정신건강복지센터 찾기
  </h2>
  <ul className="space-y-3 list-disc list-inside text-muted-foreground">
    <li>
      <a
        href="https://www.mohw.go.kr/menu.es?mid=a10706040200"
        target="_blank"
        rel="noopener noreferrer"
        className="text-blue-600 hover:text-blue-700 hover:underline dark:text-blue-400 dark:hover:text-blue-500"
      >
        광역 정신건강복지센터 찾기
      </a>
    </li>
    <li>
      <a
        href="https://www.mohw.go.kr/menu.es?mid=a10706040300"
        target="_blank"
        rel="noopener noreferrer"
        className="text-blue-600 hover:text-blue-700 hover:underline dark:text-blue-400 dark:hover:text-blue-500"
      >
        우리 동네 정신건강복지센터 찾기
      </a>
    </li>
  </ul>
</div>
        {/* --- 여기까지 섹션 추가 --- */}
      </div> {/* End of max-w-3xl div */}
    </section>
  );
}
