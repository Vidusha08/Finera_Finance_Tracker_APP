//Mapping/MappingProfile.cs

using AutoMapper;
using FineraAPI.DTOs;
using FineraAPI.Models;

namespace FineraAPI.Mapping
{
    public class MappingProfile : Profile
    {
        public MappingProfile()
        {
            // User mappings
            CreateMap<User, UserResponseDto>();
            CreateMap<RegisterDto, User>();

            // Category mappings
            CreateMap<Category, CategoryDto>();
            CreateMap<CreateCategoryDto, Category>();
            CreateMap<UpdateCategoryDto, Category>();
            
            // Budget mappings - THIS WAS MISSING
            CreateMap<Budget, BudgetDto>()
                .ForMember(dest => dest.CategoryName, opt => opt.MapFrom(src => src.Category.Name))
                .ForMember(dest => dest.CategoryType, opt => opt.MapFrom(src => src.Category.Type))
                .ForMember(dest => dest.RemainingAmount, opt => opt.MapFrom(src => src.Amount - src.SpentAmount))
                .ForMember(dest => dest.PercentageUsed, opt => opt.MapFrom(src => 
                    src.Amount > 0 ? (src.SpentAmount / src.Amount) * 100 : 0));
            
            CreateMap<CreateBudgetDto, Budget>()
                .ForMember(dest => dest.SpentAmount, opt => opt.MapFrom(src => 0));

            // Transaction mappings - NOT NEEDED since controller uses manual mapping
            
            /*// Transaction mappings - ADD THESE FOR COMPLETENESS
            CreateMap<Transaction, TransactionDto>()
                .ForMember(dest => dest.CategoryName, opt => opt.MapFrom(src => src.Category.Name))
                .ForMember(dest => dest.CategoryColor, opt => opt.MapFrom(src => src.Category.Color));*/

            /*CreateMap<Transaction, TransactionResponseDto>()
                .ForMember(dest => dest.CategoryName, opt => opt.MapFrom(src => src.Category.Name))
                .ForMember(dest => dest.CategoryColor, opt => opt.MapFrom(src => src.Category.Color))
                .ForMember(dest => dest.CategoryIcon, opt => opt.MapFrom(src => src.Category.Icon));
                
            CreateMap<CreateTransactionDto, Transaction>();*/
        }
    }
}