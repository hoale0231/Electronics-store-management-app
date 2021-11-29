import Chart from "react-apexcharts";

export default function ApexChart(props) {
    
    const series = props.series
    const options = {
        chart: {
            animations: {
                enabled: false,
            },
            type: 'bar',
            height: 350,
        },
        plotOptions: {
            bar: {
            horizontal: false,
            columnWidth: '55%',
            endingShape: 'rounded'
            },
        },
        dataLabels: {
            enabled: false
        },
        stroke: {
            show: true,
            width: 2,
            colors: ['transparent']
        },
        xaxis: {
            categories: props.categories,
        },
        yaxis: {
            title: {
            text: ''
            }
        },
        fill: {
            opacity: 1
        },
        tooltip: {
            y: {
            formatter: function (val) {
                return val + " products"
            }
            }
        }
    }
    
    return (
        <div id="chart">
            <Chart options={options} series={series} type="bar" height={350} />
        </div>
    );
}