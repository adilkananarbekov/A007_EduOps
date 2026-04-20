"use client";

import Layout from "@/components/Layout";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Users, TrendingUp, AlertCircle, UsersRound, CreditCard } from "lucide-react";
import { Breadcrumb, BreadcrumbItem, BreadcrumbLink, BreadcrumbList, BreadcrumbPage, BreadcrumbSeparator } from "@/components/ui/breadcrumb";
import { useRouter } from "next/navigation";
import { useEffect, useState } from "react";
import { set } from "react-hook-form";

const metrics = [
  {
    title: "Total Students",
    value: "450",
    icon: Users,
    trend: "+12 this month",
    trendUp: true,
  },
  {
    title: "Today's Attendance",
    value: "85%",
    icon: TrendingUp,
    trend: "Present",
    trendUp: true,
  },
  {
    title: "Outstanding Debt",
    value: "150,000 KGS",
    icon: AlertCircle,
    trend: "Requires attention",
    trendUp: false,
    highlight: true,
  },
  {
    title: "Active Groups",
    value: "32",
    icon: UsersRound,
    trend: "Classes",
    trendUp: true,
  },
];

const recentActivity = [
  {
    text: "Teacher Asan marked attendance for Group A",
    time: "5 minutes ago",
  },
  {
    text: "New student enrolled: Alina B.",
    time: "15 minutes ago",
  },
  {
    text: "Payment received: 5,000 KGS from Parent Nursultan",
    time: "1 hour ago",
  },
  {
    text: "Teacher Gulnara posted announcement to English A1",
    time: "2 hours ago",
  },
  {
    text: "New group created: Math Grade 7",
    time: "3 hours ago",
  },
];

type StudentFromList = {
  accountNumber: string,
  classGroupId: number,
  classGroupName: string,
  email: string,
  id: number,
  name: string,
  studentNumber: string,
  userId: number
}

export default function AdminDashboard() {

  const router = useRouter();
  const [studentsList, setStudentsList] = useState<StudentFromList[]>([]);
  const [totalStudents, setTotalStudents] = useState(0);
  const [totalDebt, setTotalDebt] = useState(0);
  const [totalAttendance, setTotalAttendance] = useState(0);
  const [attendanceLoading, setAttendanceLoading] = useState(true);
  const [debtLoading, setDebtLoading] = useState(true);
  const [studentsLoading, setStudentsLoading] = useState(true);

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
  
        const scheduleRes = await fetch("http://localhost:8080/api/admin/students", {
            headers: { Authorization: `Bearer ${token}` },
        });
  
        if (scheduleRes.ok) {
          const studentsData = await scheduleRes.json();
          setStudentsList(studentsData);
          setTotalStudents(studentsData.length);
          setStudentsLoading(false);

          let debtSum = 0;
          let attendancePresentSum = 0;
          let attendanceTotSum = 0;

          for (const student of studentsData) {
            const debtRes = await fetch(`http://localhost:8080/api/invoices/debt/${student.userId}`, {
            headers: { Authorization: `Bearer ${token}` },
            });
            const attendanceRes = await fetch(`http://localhost:8080/api/attendance/student/${student.userId}`, {
            headers: { Authorization: `Bearer ${token}` },
            });
      
            if (debtRes.ok) {
              const debtData = await debtRes.json();
              debtSum += debtData.totalDebt;
      
              // console.log(debtData);
              
            }
            if (attendanceRes.ok) {
              const attendanceData = await attendanceRes.json();
      
              // console.log(attendanceData);
              // console.log(attendanceData.length ? true : false);
              console.log(attendanceData[0]?.status);
              
              if (attendanceData.length) {
                attendanceTotSum += 1;
                if (attendanceData[0].status === "PRESENT") {
                  attendancePresentSum += 1;
                }
              }

            }
          }

          const percentAttendance = attendanceTotSum ? Math.round((attendancePresentSum / attendanceTotSum) * 100) : 100;
          setTotalAttendance(percentAttendance);
          setTotalDebt(debtSum);

          setAttendanceLoading(false);
          setDebtLoading(false);

          // console.log(studentsData);
          
        } else {
          router.replace("/login");
        }
      })();
  
    }, []);
  
  return (
    <Layout>
      {/* Header */}
      {/* <div className="border-b border-border bg-white">
        <div className="px-4 sm:px-8 py-4">
          <Breadcrumb>
            <BreadcrumbList>
              <BreadcrumbItem>
                <BreadcrumbLink href="#">Organization</BreadcrumbLink>
              </BreadcrumbItem>
              <BreadcrumbSeparator />
              <BreadcrumbItem>
                <BreadcrumbPage>Bishkek Branch</BreadcrumbPage>
              </BreadcrumbItem>
            </BreadcrumbList>
          </Breadcrumb>
        </div>
      </div> */}

      {/* Main Content */}
      <div className="flex-1 overflow-auto p-4 sm:p-8 bg-white">
        <div className="max-w-7xl mx-auto space-y-6 sm:space-y-8">
          {/* Page Title */}
          <div>
            <h1 className="text-2xl sm:text-3xl font-semibold text-foreground">Dashboard</h1>
            <p className="text-muted-foreground mt-1 text-sm sm:text-base">Overview of your organization</p>
          </div>

          {/* Metrics Grid */}
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 sm:gap-6">
            <Card key='Total Students' className="border-border">
              <CardHeader className="flex flex-row items-center justify-between pb-2">
                <CardTitle className="text-xs sm:text-sm font-medium text-muted-foreground">
                  Total Students
                </CardTitle>
                <Users className="w-4 h-4 sm:w-5 sm:h-5 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className={`text-2xl sm:text-3xl font-semibold ${false ? 'text-primary' : 'text-foreground'}`}>
                  {!studentsLoading ? totalStudents : "Loading..."}
                </div>
                <p className={`text-xs sm:text-sm mt-1 ${true ? 'text-muted-foreground' : 'text-primary'}`}>
                  students
                </p>
                <br />
              </CardContent>
            </Card>
            <Card key='Outstanding Debt' className="border-border">
              <CardHeader className="flex flex-row items-center justify-between pb-2">
                <CardTitle className="text-xs sm:text-sm font-medium text-muted-foreground">
                  Outstanding Debt
                </CardTitle>
                {!debtLoading ? (totalDebt > 0 ? (
                  <AlertCircle className="w-4 h-4 sm:w-5 sm:h-5 text-muted-foreground" />
                ) : (
                  <CreditCard className="w-4 h-4 sm:w-5 sm:h-5 text-muted-foreground" />
                )) : false}
                {/* <CreditCard className="w-4 h-4 sm:w-5 sm:h-5 text-muted-foreground" /> */}
              </CardHeader>
              <CardContent>
                <div className={`text-2xl sm:text-3xl font-semibold ${totalDebt > 0 && !debtLoading ? 'text-primary' : 'text-foreground'}`}>
                  {!debtLoading ? `${totalDebt} KGS` : "Loading..."}
                </div>
                <p className={`text-xs sm:text-sm mt-1 ${!(totalDebt > 0) || debtLoading ? 'text-muted-foreground' : 'text-primary'}`}>
                  {!debtLoading ? (totalDebt > 0 ? 'Requires attention' : 'All clear') : 'Status'}
                </p>
                <br />
              </CardContent>
            </Card>
            <Card key='Attendance' className="border-border">
              <CardHeader className="flex flex-row items-center justify-between pb-2">
                <CardTitle className="text-xs sm:text-sm font-medium text-muted-foreground">
                  Attendance
                </CardTitle>
                {/* <TrendingUp className="w-4 h-4 sm:w-5 sm:h-5 text-muted-foreground" /> */}
                {!attendanceLoading ? (totalAttendance < 66 ? (
                  <AlertCircle className="w-4 h-4 sm:w-5 sm:h-5 text-muted-foreground" />
                ) : (
                  <TrendingUp className="w-4 h-4 sm:w-5 sm:h-5 text-muted-foreground" />
                )) : false}
              </CardHeader>
              <CardContent>
                <div className={`text-2xl sm:text-3xl font-semibold ${totalAttendance < 66 && !attendanceLoading ? 'text-primary' : 'text-foreground'}`}>
                  {!attendanceLoading ? `${totalAttendance}%` : "Loading..."}
                </div>
                <p className={`text-xs sm:text-sm mt-1 ${!(totalAttendance < 66) || attendanceLoading ? 'text-muted-foreground' : 'text-primary'}`}>
                  Present
                </p>
                <br />
              </CardContent>
            </Card>
            {/* {metrics.map((metric) => {
              const Icon = metric.icon;
              return (
                <Card key={metric.title} className="border-border">
                  <CardHeader className="flex flex-row items-center justify-between pb-2">
                    <CardTitle className="text-xs sm:text-sm font-medium text-muted-foreground">
                      {metric.title}
                    </CardTitle>
                    <Icon className="w-4 h-4 sm:w-5 sm:h-5 text-muted-foreground" />
                  </CardHeader>
                  <CardContent>
                    <div className={`text-2xl sm:text-3xl font-semibold ${metric.highlight ? 'text-primary' : 'text-foreground'}`}>
                      {metric.value}
                    </div>
                    <p className={`text-xs sm:text-sm mt-1 ${metric.trendUp ? 'text-muted-foreground' : 'text-primary'}`}>
                      {metric.trend}
                    </p>
                  </CardContent>
                </Card>
              );
            })} */}
          </div>

          {/* Recent Activity */}
          {/* <Card className="border-border">
            <CardHeader>
              <CardTitle className="text-lg sm:text-xl">Recent Activity</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-3 sm:space-y-4">
                {recentActivity.map((activity, index) => (
                  <div
                    key={index}
                    className="flex items-start gap-3 sm:gap-4 pb-3 sm:pb-4 last:pb-0 border-b last:border-0 border-border"
                  >
                    <div className="w-2 h-2 rounded-full bg-primary mt-2 shrink-0" />
                    <div className="flex-1">
                      <p className="text-xs sm:text-sm text-foreground">{activity.text}</p>
                      <p className="text-[10px] sm:text-xs text-muted-foreground mt-1">{activity.time}</p>
                    </div>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card> */}
        </div>
      </div>
    </Layout>
  );
}