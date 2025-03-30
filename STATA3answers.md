## 📊 Results Summary

As sample size `N` increases, we observe a clear pattern across all results:

### 🔹 Boxplot
![Boxplot](./box.png)
The variability in beta estimates **narrows** significantly.  
- At `N = 10`, the estimates are widely dispersed with many outliers.  
- At `N = 10,000`, the distribution becomes extremely **tight around β ≈ 2**.

### 🔹 Histogram
![Histogram](./histo.png)
The density becomes increasingly **peaked and narrow** with higher `N`,  
indicating **more precise estimates** centered around the true beta.

### 🔹 Table
![Table](./table1.png)
- The **Standard Error (SEM)** drops sharply:
  - From `0.354` at `N = 10`
  - To `0.010` at `N = 10,000`
- The **Confidence Interval (CI) width** also shrinks:
  - From approximately `1.63` to `0.039`

### ✅ Conclusion
Increasing the sample size leads to:
- More **precise**
- More **stable**
- More **reliable** beta estimates  
This is achieved by reducing **sampling variability** and **narrowing the confidence intervals**.

---


