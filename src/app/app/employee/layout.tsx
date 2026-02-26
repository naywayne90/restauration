import EmployeeLayout from "@/components/layouts/employee-layout";

export default function Layout({ children }: { children: React.ReactNode }) {
  return <EmployeeLayout>{children}</EmployeeLayout>;
}
