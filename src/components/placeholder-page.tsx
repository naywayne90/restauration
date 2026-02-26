import type { LucideIcon } from "lucide-react";
import { Construction } from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";

interface PlaceholderPageProps {
  title: string;
  icon?: LucideIcon;
}

export default function PlaceholderPage({ title, icon: Icon = Construction }: PlaceholderPageProps) {
  return (
    <div className="flex items-center justify-center min-h-[60vh]">
      <Card className="w-full max-w-md">
        <CardContent className="flex flex-col items-center gap-4 pt-6 text-center">
          <div className="flex h-16 w-16 items-center justify-center rounded-full bg-orange-100">
            <Icon className="h-8 w-8 text-orange-500" />
          </div>
          <h1 className="text-2xl font-bold">{title}</h1>
          <p className="text-muted-foreground">Module en construction</p>
        </CardContent>
      </Card>
    </div>
  );
}
