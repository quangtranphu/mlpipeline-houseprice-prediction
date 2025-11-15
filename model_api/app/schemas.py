from pydantic import BaseModel

class HouseInfo(BaseModel):
    MSSubClass: int = 60
    MSZoning: str = "RL"
    LotArea: int = 7844
    LotConfig: str = "Inside"
    BldgType: str = "1Fam"
    OverallCond: int = 7
    YearBuilt: int = 1978
    YearRemodAdd: int = 1978
    Exterior1st: str = "HdBoard"
    BsmtFinSF2: float = 0.0
    TotalBsmtSF: float = 672.00