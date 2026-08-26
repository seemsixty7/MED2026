using System;

namespace MEDDotNet
{
    internal class MedScaleChoice
    {
        public string Label;
        public double Sc;
        public double PlotScale;

        public override string ToString()
        {
            return Label;
        }

        public static MedScaleChoice[] All()
        {
            return new MedScaleChoice[]
            {
                new MedScaleChoice { Label = "Full Size 1=1  (1)", Sc = 1.0, PlotScale = 1.0 },
                new MedScaleChoice { Label = "Arch  3\" = 1'-0\"  (4)", Sc = 4.0, PlotScale = 1.0 },
                new MedScaleChoice { Label = "Arch  1-1/2\" = 1'-0\"  (8)", Sc = 8.0, PlotScale = 1.0 },
                new MedScaleChoice { Label = "Arch  1\" = 1'-0\"  (12)", Sc = 12.0, PlotScale = 1.0 },
                new MedScaleChoice { Label = "Arch  3/4\" = 1'-0\"  (16)", Sc = 16.0, PlotScale = 1.0 },
                new MedScaleChoice { Label = "Arch  1/2\" = 1'-0\"  (24)", Sc = 24.0, PlotScale = 1.0 },
                new MedScaleChoice { Label = "Arch  3/8\" = 1'-0\"  (32)", Sc = 32.0, PlotScale = 1.0 },
                new MedScaleChoice { Label = "Arch  1/4\" = 1'-0\"  (48)", Sc = 48.0, PlotScale = 1.0 },
                new MedScaleChoice { Label = "Arch  3/16\" = 1'-0\"  (64)", Sc = 64.0, PlotScale = 1.0 },
                new MedScaleChoice { Label = "Arch  1/8\" = 1'-0\"  (96)", Sc = 96.0, PlotScale = 1.0 },
                new MedScaleChoice { Label = "Arch  3/32\" = 1'-0\"  (128)", Sc = 128.0, PlotScale = 1.0 },
                new MedScaleChoice { Label = "Arch  1/16\" = 1'-0\"  (192)", Sc = 192.0, PlotScale = 1.0 },
                new MedScaleChoice { Label = "Eng  1\" = 10'-0\"  (120)", Sc = 120.0, PlotScale = 1.0 },
                new MedScaleChoice { Label = "Eng  1\" = 20'-0\"  (240)", Sc = 240.0, PlotScale = 1.0 },
                new MedScaleChoice { Label = "Eng  1\" = 30'-0\"  (360)", Sc = 360.0, PlotScale = 1.0 },
                new MedScaleChoice { Label = "Eng  1\" = 40'-0\"  (480)", Sc = 480.0, PlotScale = 1.0 },
                new MedScaleChoice { Label = "Eng  1\" = 50'-0\"  (600)", Sc = 600.0, PlotScale = 1.0 },
                new MedScaleChoice { Label = "Eng  1\" = 60'-0\"  (720)", Sc = 720.0, PlotScale = 1.0 },
                new MedScaleChoice { Label = "Eng  1\" = 100'-0\"  (1200)", Sc = 1200.0, PlotScale = 1.0 },
                new MedScaleChoice { Label = "Eng  1\" = 200'-0\"  (2400)", Sc = 2400.0, PlotScale = 1.0 },
                new MedScaleChoice { Label = "Metric 1 = 1  (1)", Sc = 1.0, PlotScale = 25.4 },
                new MedScaleChoice { Label = "Metric 1 = 500  (500)", Sc = 500.0, PlotScale = 25.4 },
                new MedScaleChoice { Label = "Metric 1 = 1000  (1000)", Sc = 1000.0, PlotScale = 25.4 },
                new MedScaleChoice { Label = "Metric 1 = 1250  (1250)", Sc = 1250.0, PlotScale = 25.4 },
                new MedScaleChoice { Label = "Metric 1 = 1500  (1500)", Sc = 1500.0, PlotScale = 25.4 },
                new MedScaleChoice { Label = "Metric 1 = 2000  (2000)", Sc = 2000.0, PlotScale = 25.4 },
                new MedScaleChoice { Label = "Metric 1 = 2500  (2500)", Sc = 2500.0, PlotScale = 25.4 }
            };
        }
    }
}