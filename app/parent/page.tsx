"use client";

import Layout from "@/components/Layout";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { AlertCircle, TrendingUp, Clock, MapPin } from "lucide-react";
import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { Badge } from "@/components/ui/badge";
import Link from "next/navigation";

type Lesson = {
  classGroupId: number;
  classGroupName: string;
  dayOfWeek: string;
  endTime: string;
  id: number;
  lessonNumber: number;
  room: string;
  startTime: string;
  subjectId: number;
  subjectName: string;
  teacherId: number;
  teacherName: string;
}

function timeToMinutes(time: string) {
  const [h, m] = time.split(":").map(Number)
  return h * 60 + m
}

function getCurrentOrNextLesson(lessons: Lesson[], time: Date) {
  // const now = new Date(2026, 2, 25, 8, 46)
  // const now = new Date()
  const now = time;
  const currentMinutes = now.getHours() * 60 + now.getMinutes()

  const currentLesson = lessons.find(lesson => {
    const start = timeToMinutes(lesson.startTime)
    const end = timeToMinutes(lesson.endTime)
    return currentMinutes >= start && currentMinutes <= end
  })

  if (currentLesson) {
    return { type: "Current", lesson: currentLesson }
  }

  const nextLesson = lessons.find(lesson => {
    const start = timeToMinutes(lesson.startTime)
    return currentMinutes < start
  })

  if (nextLesson) {
    return { type: "Next", lesson: nextLesson }
  }

  return null
}

export default function ParentDashboard() {

  const router = useRouter();

  const [studentName, setStudentName] = useState("Loading...");
  const [hasDebt, setHasDebt] = useState(false);
  const [debtAmount, setDebtAmount] = useState(0);
  const [attendanceRate, setAttendanceRate] = useState(0);
  const [lesson, setLesson] = useState<any>(null);
  const [classesPerWeek, setClassesPerWeek] = useState(0);

  useEffect(() => {

    (async () => {
      const userDataRaw = localStorage.getItem("userData");
      if (!userDataRaw) {
        // Redirect to login if no token is found
        router.replace("/login");
        return;
      }
      const userData = JSON.parse(userDataRaw);
      const token = userData.token;

      setStudentName(userData.firstName);

      const [scheduleRes, attendanceRes, debtRes] = await Promise.all([
        fetch("http://136.116.64.6/api/schedule/week", {
          headers: { Authorization: `Bearer ${token}` },
        }),
        fetch("http://136.116.64.6/api/attendance/stats", {
          headers: { Authorization: `Bearer ${token}` },
        }),
        fetch(`http://136.116.64.6/api/invoices/debt/${userData.userId}`, {
          headers: { Authorization: `Bearer ${token}` },
        })
      ])

      if (scheduleRes.ok && attendanceRes.ok && debtRes.ok) {
        const scheduleData = await scheduleRes.json();
        const attendanceData = await attendanceRes.json();
        const debtData = await debtRes.json();

        setDebtAmount(debtData.totalDebt);
        if (debtData.totalDebt <= 0) {
          setHasDebt(false);
        } else {
          setHasDebt(true);
        }

        if (attendanceData.present + attendanceData.excused + attendanceData.late + attendanceData.absent === 0) {
          setAttendanceRate(100);
        } else {
          const newattendanceRate = Math.round((attendanceData.present + attendanceData.excused + attendanceData.late) / (attendanceData.present + attendanceData.excused + attendanceData.late + attendanceData.absent) * 100);
          setAttendanceRate(newattendanceRate);
        }

        // const todayDate = new Date(2026, 2, 25, 8, 44);
        // const todayDate = new Date(2026, 2, 25, 10, 30);
        const todayDate = new Date();
        const today = todayDate
          .toLocaleDateString("en-US", { weekday: "long" })
          .toUpperCase();

        const todayLessons = scheduleData.filter(
          (l: any) => l.dayOfWeek === today
        );
        
        const currentOrNext = getCurrentOrNextLesson(todayLessons, todayDate);
        setLesson(currentOrNext);
        
        const cpw = scheduleData.filter(
          (l: any) => l.subjectName === currentOrNext?.lesson.subjectName
        );
        setClassesPerWeek(cpw.length);

        // console.log(debtData);
        // console.log(attendanceData, scheduleData, debtAmount, hasDebt);
        // console.log(todayLessons, currentOrNext, cpw.length);
        
      } else {
        router.replace("/login");
      }
    })();

  }, []);

  return (
    <Layout userRole="parent">
      {/* Header */}
      <header className="border-b border-border bg-white px-4 sm:px-8 py-4 sm:py-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl sm:text-3xl font-semibold text-foreground">Welcome back, {studentName}</h1>
            <p className="text-muted-foreground mt-1 text-sm sm:text-base">Here's your overview for today</p>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="flex-1 overflow-auto bg-white p-4 sm:p-8">
        <div className="max-w-7xl mx-auto space-y-4 sm:space-y-6">
          {/* Priority Card - Debt */}
          {hasDebt && (
            <Card className="border-2 border-primary bg-red-50">
              <CardContent className="p-4 sm:p-5">
                <div className="flex items-start gap-3 mb-4">
                  <div className="p-2 bg-primary rounded-full">
                    <AlertCircle className="w-4 h-4 sm:w-5 sm:h-5 text-white" />
                  </div>
                  <div className="flex-1">
                    <h3 className="font-semibold text-foreground text-sm mb-1">Outstanding Balance</h3>
                    <p className="text-xl sm:text-2xl font-bold text-primary">{debtAmount.toLocaleString()} KGS</p>
                  </div>
                </div>
                <Button className="w-full bg-primary hover:bg-primary/90 h-10 sm:h-12 text-sm sm:text-base font-semibold">
                  Pay Now
                </Button>
              </CardContent>
            </Card>
          )}

          {/* Progress Card - Attendance */}
          <Card className="border-border">
            <CardContent className="p-4 sm:p-5">
              <div className="flex items-center justify-between mb-4">
                <div className="flex items-center gap-3">
                  <div className="p-2 bg-accent/10 rounded-full">
                    <TrendingUp className="w-4 h-4 sm:w-5 sm:h-5 text-accent" />
                  </div>
                  <div>
                    <h3 className="font-semibold text-foreground text-sm sm:text-base">Attendance</h3>
                    <p className="text-xl sm:text-2xl font-bold text-foreground mt-1">{attendanceRate}%</p>
                  </div>
                </div>
              </div>
              <div className="w-full bg-muted rounded-full h-2.5 sm:h-3">
                <div
                  className="bg-primary h-2.5 sm:h-3 rounded-full transition-all"
                  style={{ width: `${attendanceRate}%` }}
                />
              </div>
              <p className="text-sm text-muted-foreground mt-2">This month</p>
            </CardContent>
          </Card>

          {/* Schedule Preview */}
          {lesson ? (
            <Card className="border-border">
              <CardContent className="p-4 sm:p-5">
                <h3 className="font-semibold text-foreground mb-4 text-sm sm:text-base">{lesson.type} Class</h3>
                <div className="space-y-3">
                  <div className="flex items-center justify-between">
                    <span className="text-base sm:text-lg font-bold text-foreground">{lesson.lesson.subjectName}</span>
                    {/* <span className="text-xs sm:text-sm font-medium text-muted-foreground">Today</span> */}
                  </div>
                  <div className="flex flex-col sm:flex-row items-start sm:items-center gap-2 sm:gap-4 text-sm text-muted-foreground">
                    <div className="flex items-center gap-2">
                      <Clock className="w-4 h-4" />
                      <span>{lesson.lesson.startTime} - {lesson.lesson.endTime}</span>
                    </div>
                    <div className="flex items-center gap-2">
                      <MapPin className="w-4 h-4" />
                      <span>Room {lesson.lesson.room}</span>
                    </div>
                  </div>
                  <div className="pt-2 border-t border-border">
                    <p className="text-sm text-muted-foreground">
                      Teacher: <span className="text-foreground font-medium">{lesson.lesson.teacherName}</span>
                    </p>
                  </div>
                </div>
              </CardContent>
            </Card>
          ) : (
            <Card className="border-border">
              <CardContent className="p-4 sm:p-5 flex items-center justify-center h-45">
                <p className="text-muted-foreground text-sm sm:text-base text-center">
                  You're done for today!
                </p>
              </CardContent>
            </Card>
          )}

          {/* Quick Stats */}
          <div className="grid grid-cols-2 gap-3 sm:gap-4">
            {lesson && (
              <>
              <Card className="border-border">
                <CardContent className="p-3 sm:p-4 text-center">
                  <p className="text-xl sm:text-2xl font-bold text-foreground">{classesPerWeek}</p>
                  <p className="text-xs sm:text-sm text-muted-foreground mt-1">Classes/Week</p>
                </CardContent>
              </Card>
              <Card className="border-border">
                <CardContent className="p-3 sm:p-4 text-center">
                  <p className="text-xl sm:text-2xl font-bold text-foreground">???????????</p>
                  <p className="text-xs sm:text-sm text-muted-foreground mt-1">Active Groups</p>
                </CardContent>
              </Card>
              </>
            )}
          </div>
        </div>
      </main>
    </Layout>
  );
}