import UIKit
import DGCharts
import Charts

class ChartViewController: UIViewController {
    private let chartView: LineChartView = {
        let chartView = LineChartView()
        chartView.backgroundColor = .white
        chartView.rightAxis.enabled = false
        
        let yAxis = chartView.leftAxis
        yAxis.labelFont = .systemFont(ofSize: 12)
        yAxis.setLabelCount(6, force: false)
        yAxis.labelTextColor = .gray
        yAxis.axisLineColor = .lightGray
        yAxis.labelPosition = .outsideChart
        
        let xAxis = chartView.xAxis
        xAxis.labelPosition = .bottom
        xAxis.labelFont = .systemFont(ofSize: 12)
        xAxis.setLabelCount(5, force: false)
        xAxis.labelTextColor = .gray
        xAxis.axisLineColor = .lightGray
        
        chartView.animate(xAxisDuration: 1.5)
        chartView.legend.form = .circle
        
        chartView.translatesAutoresizingMaskIntoConstraints = false
        return chartView
    }()
    
    private let infoLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .gray
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let refreshButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Refresh Data", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = .appPrimary
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let loadingView = LoadingView(message: "Loading chart data...")
    private var errorView: ErrorView?
    
    private let viewModel: ChartViewModel
    
    init(baseCurrencyCode: String, targetCurrencyCode: String) {
        self.viewModel = ChartViewModel(baseCurrencyCode: baseCurrencyCode, targetCurrencyCode: targetCurrencyCode)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupBindings()
        viewModel.viewDidLoad()
    }
    
    private func setupViews() {
        view.backgroundColor = .appBackground
        title = "\(viewModel.baseCurrencyCode)/\(viewModel.targetCurrencyCode) History"
        
        view.addSubview(chartView)
        view.addSubview(infoLabel)
        view.addSubview(refreshButton)
        
        NSLayoutConstraint.activate([
            chartView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            chartView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            chartView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            chartView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.5),
            
            infoLabel.topAnchor.constraint(equalTo: chartView.bottomAnchor, constant: 16),
            infoLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            infoLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            refreshButton.topAnchor.constraint(equalTo: infoLabel.bottomAnchor, constant: 24),
            refreshButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            refreshButton.widthAnchor.constraint(equalToConstant: 160),
            refreshButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        refreshButton.addTarget(self, action: #selector(refreshData), for: .touchUpInside)
        
        // Setup loading view
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingView)
        NSLayoutConstraint.activate([
            loadingView.topAnchor.constraint(equalTo: view.topAnchor),
            loadingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loadingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            loadingView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        loadingView.isHidden = true
    }
    
    private func setupBindings() {
        viewModel.onChartDataUpdated = { [weak self] entries, dates in
            DispatchQueue.main.async {
                self?.updateChart(with: entries, dates: dates)
            }
        }
        
        viewModel.onInfoUpdated = { [weak self] info in
            DispatchQueue.main.async {
                self?.infoLabel.text = info
            }
        }
        
        viewModel.onLoading = { [weak self] isLoading in
            DispatchQueue.main.async {
                if isLoading {
                    self?.loadingView.startAnimating()
                } else {
                    self?.loadingView.stopAnimating()
                }
            }
        }
        
        viewModel.onError = { [weak self] message in
            DispatchQueue.main.async {
                self?.showError(message: message)
            }
        }
    }
    
    private func updateChart(with entries: [ChartDataEntry], dates: [Date]) {
        // Create a line data set
        let dataSet = LineChartDataSet(entries: entries, label: "\(viewModel.targetCurrencyCode) per \(viewModel.baseCurrencyCode)")
        dataSet.drawCirclesEnabled = true
        dataSet.circleRadius = 4
        dataSet.circleColors = [.appPrimary]
        dataSet.setColor(.appPrimary)
        dataSet.lineWidth = 2
        dataSet.mode = .cubicBezier
        dataSet.drawValuesEnabled = true
        dataSet.valueFont = .systemFont(ofSize: 10)
        dataSet.valueTextColor = .gray
        dataSet.drawFilledEnabled = true
        dataSet.fillColor = .appPrimary.withAlphaComponent(0.1)
        dataSet.fillAlpha = 0.5
        
        // Create line data object with the data set
        let lineData = LineChartData(dataSet: dataSet)
        
        // Format x-axis with dates
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd"
        
        chartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: dates.map { dateFormatter.string(from: $0) })
        
        // Set data to chart view
        chartView.data = lineData
        chartView.notifyDataSetChanged()
    }
    
    private func showError(message: String) {
        errorView?.removeFromSuperview()
        
        let errorView = ErrorView(message: message)
        errorView.translatesAutoresizingMaskIntoConstraints = false
        errorView.retryAction = { [weak self] in
            self?.viewModel.refreshData()
            errorView.removeFromSuperview()
            self?.errorView = nil
        }
        
        view.addSubview(errorView)
        NSLayoutConstraint.activate([
            errorView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            errorView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            errorView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            errorView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        self.errorView = errorView
    }
    
    @objc private func refreshData() {
        viewModel.refreshData()
    }
}
