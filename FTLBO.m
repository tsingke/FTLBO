function [gbestx,gbestfitness,gbesthistory]=FTLBO(popsize,dimension,xmax,xmin,vmax,vmin,MaxFEs,Func,FuncId)

IterFEs=popsize*3;  %每一次迭代评价多少次
MaxIter=ceil((MaxFEs-popsize)/IterFEs);  %最多需要迭代多少次
overFEs = MaxIter*IterFEs+popsize;
gbesthistory=inf(1,overFEs);  %存储每次FEs的数据；
FEsfitness = inf;
FEs = 0;

if size(xmin,2) == 1
    xmin = repmat(xmin,1,dimension);
    xmax = repmat(xmax,1,dimension);
end

pop = repmat(xmin,popsize,1)+repmat((xmax-xmin),popsize,1).*rand(popsize,dimension);  %初始化种群
Fitness= inf(1,popsize);

for z = 1:popsize
    FEs = FEs+1;
    Fitness(z) = Func(pop(z,:)',FuncId);
    FEsfitness = min([FEsfitness,Fitness(z)]);
    gbesthistory(FEs)= FEsfitness;
end

gbestx = rand(1,dimension);

while FEs<=MaxFEs
    %% 更新当前全局最优解
    [~,gbestindex]=min(Fitness);
    gbestx = pop(gbestindex,:);
   
    %% 种群开始迭代
    new_fitness = inf(1,popsize);
    new_pop = inf(popsize,dimension);
    Phase = [1:(gbestindex-1),(gbestindex+1):popsize];

        for i = Phase
                   
                    Cx = pop(i,:);
                    Oppop = pop(i,:);
                    Upindex = Cx>gbestx; %大于最优值的变量
                    Upp = (xmax(Upindex)-Cx(Upindex))./(xmax(Upindex)-gbestx(Upindex)); %上比例
                    Oppop(Upindex) = xmin(Upindex)+Upp.*(gbestx(Upindex)-xmin(Upindex));
                    
                    Downindex = Cx<gbestx;   %小于最优值变量
                    Downp = (Cx(Downindex)-xmin(Downindex))./(gbestx(Downindex)-xmin(Downindex)); %下比例
                    temp = xmax(Downindex)-Downp.*(xmax(Downindex)-gbestx(Downindex));
                    Oppop(Downindex) = temp;
                    
                    OPP_index = rand(1,dimension)<0.5;
         
                    Oppop(OPP_index) = Cx(OPP_index);
                    Oppop = min(max(Oppop,xmin),xmax);
                    new_pop(i,:) = Oppop;
                    %评价翻转个体
                    new_fitness(i) = Func(Oppop',FuncId);
                    FEs = FEs+1;
                    FEsfitness = min([new_fitness(i),FEsfitness]);
                    gbesthistory(FEs) = FEsfitness;
        end
        
    %对最优个体进行反向学习，上下界同时学习
    OpX = gbestx;
    Uinterven = (xmax-OpX)*(FEs/MaxFEs); %上界的反向间距
    UOblx = xmax-Uinterven; %反向个体
    Dinterven = (OpX-xmin)*(FEs/MaxFEs); %下界的反向间距
    DOblx = xmin+Dinterven; %反向个体
    pc1 = rand(1,dimension)>0.5;
    pc2 = ~pc1;
    OpX(pc1) = UOblx(pc1);
    OpX(pc2) = DOblx(pc2);
    OpX = min(max(OpX,xmin),xmax);
    new_pop(gbestindex,:) = OpX;
    %评价反向个体
    
    new_fitness(gbestindex) = Func(OpX',FuncId);
    FEs = FEs+1;
    FEsfitness = min([new_fitness(gbestindex),FEsfitness]);
    gbesthistory(FEs) = FEsfitness;
    
    
    %% 替换为新个体
    betterIndex = new_fitness<Fitness;
    pop(betterIndex,:) = new_pop(betterIndex,:);
    Fitness(betterIndex) = new_fitness(betterIndex);
    
    %% 开始第二阶段双向学习
    new_fitness = inf(1,popsize);
    new_pop = inf(popsize,dimension);
    for j=1:popsize
        
        %随机选择第一个个体进行学习
        p = randi([1 popsize],1,1);     
        while j == p
            p = randi([1 popsize],1,1);  % Selection of random parter
        end
         LearnX = pop(j,:);
        %% 同样进行双向学习
         Cx = pop(j,:);
         Oppop = pop(j,:);
         Upindex = Cx>LearnX; %大于最优值的变量
         Upp = (xmax(Upindex)-Cx(Upindex))./(xmax(Upindex)-LearnX(Upindex)); %上比例
         Oppop(Upindex) = xmin(Upindex)+Upp.*(LearnX(Upindex)-xmin(Upindex));
         
         Downindex = Cx<LearnX;   %小于最优值变量
         Downp = (Cx(Downindex)-xmin(Downindex))./(LearnX(Downindex)-xmin(Downindex)); %下比例
         temp = xmax(Downindex)-Downp.*(xmax(Downindex)-LearnX(Downindex));
         Oppop(Downindex) = temp;
         
         OPP_index = rand(1,dimension)<0.5;
         Oppop(OPP_index) = Cx(OPP_index);
         Oppop = min(max(Oppop,xmin),xmax);
         new_pop(j,:) = Oppop;
         %评价反向个体
         Oppop_Fitness= Func(Oppop',FuncId);
         FEs = FEs+1;
         FEsfitness = min([Oppop_Fitness,FEsfitness]);
         gbesthistory(FEs) = FEsfitness;
        
        if Fitness(p)< Fitness(j)    % 如果p比j更好则靠近它
            Xnew = pop(j,:) + rand(1, dimension).*(pop(p,:) - pop(j,:));  % Generating the new solution
            Xnew2 = Oppop+rand(1,dimension).*(pop(p,:)-Oppop);
            Xnew(OPP_index) = Xnew2(OPP_index);
        else %否则远离它
            Xnew = pop(j,:) - rand(1, dimension).*(pop(p,:) - pop(j,:));  % Generating the new solution
            Xnew2 = Oppop-rand(1,dimension).*(pop(p,:)-Oppop);
            Xnew(OPP_index) = Xnew2(OPP_index);
        end
        
         Xnew = min(xmax, Xnew);       % Bounding the violating variables to their upper bound
         Xnew = max(xmin, Xnew);       % Bounding the violating variables to their lower bound
         new_pop(j,:) = Xnew;
        Xnew_Fitness = Func(Xnew',FuncId);
        FEs = FEs+1;
        FEsfitness = min([Xnew_Fitness,FEsfitness]);
        gbesthistory(FEs) = FEsfitness;
        if Oppop_Fitness<=Xnew_Fitness
            new_pop(j,:)=Oppop;
            new_fitness(j) = Oppop_Fitness;
        else
            new_pop(j,:) = Xnew;
            new_fitness(j) = Xnew_Fitness;
        end
    end
    b = new_fitness<Fitness;
    pop(b,:) = new_pop(b,:);
    Fitness(b) = new_fitness(b);
    
    fprintf('%d--%d\n',FEs,FEsfitness);
    
end

gbesthistory = gbesthistory(1:MaxFEs);
gbestfitness = gbesthistory(MaxFEs);

end
